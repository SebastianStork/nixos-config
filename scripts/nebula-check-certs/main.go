package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/netip"
	"os"
	"slices"
	"sort"
	"strings"
	"time"

	"github.com/slackhq/nebula/cert"
)

const minValidFor = 30 * 24 * time.Hour

type host struct {
	Name           string   `json:"name"`
	Certificate    string   `json:"certificate"`
	PublicKey      string   `json:"publicKey"`
	CA             string   `json:"ca"`
	Networks       []string `json:"networks"`
	UnsafeNetworks []string `json:"unsafeNetworks"`
	Groups         []string `json:"groups"`
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "usage: %s <hosts.json>\n", os.Args[0])
		os.Exit(2)
	}

	b, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to read hosts: %v\n", err)
		os.Exit(1)
	}

	var hosts []host
	if err := json.Unmarshal(b, &hosts); err != nil {
		fmt.Fprintf(os.Stderr, "failed to parse hosts: %v\n", err)
		os.Exit(1)
	}

	if len(hosts) == 0 {
		fmt.Fprintf(os.Stderr, "no nebula hosts to check\n")
		os.Exit(1)
	}

	caPath := hosts[0].CA
	var caPathProblems []string
	for _, h := range hosts {
		if h.CA != caPath {
			caPathProblems = append(caPathProblems, fmt.Sprintf("%s: CA mismatch: got %q, want %q", h.Name, h.CA, caPath))
		}
	}
	failIfProblems(caPathProblems)

	now := time.Now()
	validUntil := now.Add(minValidFor)

	pool, caProblems := checkCA(caPath, now, validUntil)
	failIfProblems(caProblems)
	if pool == nil {
		fail([]string{"CA check did not return a certificate pool"})
	}

	var hostProblems []string
	for _, h := range hosts {
		problems := checkHost(h, pool, now, validUntil)
		hostProblems = append(hostProblems, problems...)
	}
	failIfProblems(hostProblems)

	fmt.Printf("checked %d nebula host certificates; all are valid until at least %s\n", len(hosts), validUntil.Format(time.RFC3339))
}

func failIfProblems(problems []string) {
	if len(problems) == 0 {
		return
	}
	fail(problems)
}

func fail(problems []string) {
	for _, problem := range problems {
		fmt.Fprintf(os.Stderr, "%s\n", problem)
	}
	os.Exit(1)
}

func checkCA(path string, now, validUntil time.Time) (*cert.CAPool, []string) {
	certs, err := readCertificates(path)
	if err != nil {
		return nil, []string{fmt.Sprintf("CA %s: %v", path, err)}
	}
	if len(certs) != 1 {
		return nil, []string{fmt.Sprintf("CA %s: expected exactly one CA certificate, found %d", path, len(certs))}
	}

	c := certs[0]
	label := fmt.Sprintf("CA %s", path)
	if !c.IsCA() {
		return nil, []string{fmt.Sprintf("%s: certificate is not a CA", label)}
	}

	pool := cert.NewCAPool()
	var problems []string
	if !c.CheckSignature(c.PublicKey()) {
		problems = append(problems, fmt.Sprintf("%s (%s): certificate is not self-signed", label, c.Name()))
	}
	if c.Expired(now) {
		problems = append(problems, fmt.Sprintf("%s (%s): certificate is not valid now; valid from %s to %s", label, c.Name(), c.NotBefore().Format(time.RFC3339), c.NotAfter().Format(time.RFC3339)))
	}
	if c.Expired(validUntil) {
		problems = append(problems, fmt.Sprintf("%s (%s): certificate will not be valid at %s; valid until %s", label, c.Name(), validUntil.Format(time.RFC3339), c.NotAfter().Format(time.RFC3339)))
	}
	if len(problems) > 0 {
		return nil, problems
	}

	if err := pool.AddCA(c); err != nil {
		return nil, []string{fmt.Sprintf("%s (%s): failed to add CA to pool: %v", label, c.Name(), err)}
	}
	return pool, nil
}

func checkHost(h host, pool *cert.CAPool, now, validUntil time.Time) []string {
	certs, err := readCertificates(h.Certificate)
	if err != nil {
		return []string{fmt.Sprintf("%s: %v", h.Name, err)}
	}
	if len(certs) != 1 {
		return []string{fmt.Sprintf("%s: expected exactly one host certificate in %s, found %d", h.Name, h.Certificate, len(certs))}
	}

	publicKey, publicKeyCurve, err := readPublicKey(h.PublicKey)
	if err != nil {
		return []string{fmt.Sprintf("%s: %v", h.Name, err)}
	}

	expectedNetworks, err := parsePrefixes(h.Networks)
	if err != nil {
		return []string{fmt.Sprintf("%s: invalid expected networks: %v", h.Name, err)}
	}
	expectedUnsafeNetworks, err := parsePrefixes(h.UnsafeNetworks)
	if err != nil {
		return []string{fmt.Sprintf("%s: invalid expected unsafe networks: %v", h.Name, err)}
	}

	c := certs[0]
	label := fmt.Sprintf("%s cert", h.Name)
	if c.IsCA() {
		return []string{fmt.Sprintf("%s: host certificate is a CA", label)}
	}

	var problems []string
	if c.Name() != h.Name {
		problems = append(problems, fmt.Sprintf("%s: name mismatch: got %q, want %q", label, c.Name(), h.Name))
	}
	if c.Curve() != publicKeyCurve {
		problems = append(problems, fmt.Sprintf("%s: public key curve mismatch: got %s in cert, want %s from %s", label, c.Curve(), publicKeyCurve, h.PublicKey))
	}
	if !bytes.Equal(c.PublicKey(), publicKey) {
		problems = append(problems, fmt.Sprintf("%s: public key mismatch with %s", label, h.PublicKey))
	}
	if !sameStrings(prefixStrings(c.Networks()), expectedNetworks) {
		problems = append(problems, fmt.Sprintf("%s: networks mismatch: got %v, want %v", label, prefixStrings(c.Networks()), expectedNetworks))
	}
	if !sameStrings(prefixStrings(c.UnsafeNetworks()), expectedUnsafeNetworks) {
		problems = append(problems, fmt.Sprintf("%s: unsafe networks mismatch: got %v, want %v", label, prefixStrings(c.UnsafeNetworks()), expectedUnsafeNetworks))
	}
	if !sameStrings(c.Groups(), h.Groups) {
		problems = append(problems, fmt.Sprintf("%s: groups mismatch: got %v, want %v", label, sortedStrings(c.Groups()), sortedStrings(h.Groups)))
	}
	if _, err := pool.VerifyCertificate(now, c); err != nil {
		problems = append(problems, fmt.Sprintf("%s: certificate is not valid now: %v", label, err))
	}
	if _, err := pool.VerifyCertificate(validUntil, c); err != nil {
		problems = append(problems, fmt.Sprintf("%s: certificate will not be valid at %s: %v", label, validUntil.Format(time.RFC3339), err))
	}

	return problems
}

func readCertificates(path string) ([]cert.Certificate, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read %s: %w", path, err)
	}

	var certs []cert.Certificate
	for len(bytes.TrimSpace(b)) > 0 {
		c, rest, err := cert.UnmarshalCertificateFromPEM(b)
		if err != nil {
			return nil, fmt.Errorf("failed to parse %s: %w", path, err)
		}
		certs = append(certs, c)
		b = rest
	}
	if len(certs) == 0 {
		return nil, fmt.Errorf("%s contains no certificates", path)
	}
	return certs, nil
}

func readPublicKey(path string) ([]byte, cert.Curve, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to read public key %s: %w", path, err)
	}

	publicKey, rest, curve, err := cert.UnmarshalPublicKeyFromPEM(b)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to parse public key %s: %w", path, err)
	}
	if len(bytes.TrimSpace(rest)) > 0 {
		return nil, 0, fmt.Errorf("public key %s contains extra data", path)
	}
	return publicKey, curve, nil
}

func parsePrefixes(values []string) ([]string, error) {
	prefixes := make([]string, 0, len(values))
	for _, value := range values {
		prefix, err := netip.ParsePrefix(value)
		if err != nil {
			return nil, err
		}
		prefixes = append(prefixes, prefix.String())
	}
	return prefixes, nil
}

func prefixStrings(prefixes []netip.Prefix) []string {
	values := make([]string, 0, len(prefixes))
	for _, prefix := range prefixes {
		values = append(values, prefix.String())
	}
	return values
}

func sameStrings(a, b []string) bool {
	return slices.Equal(sortedStrings(a), sortedStrings(b))
}

func sortedStrings(values []string) []string {
	values = append([]string(nil), values...)
	for i, value := range values {
		values[i] = strings.TrimSpace(value)
	}
	sort.Strings(values)
	return values
}
