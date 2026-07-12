package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/netip"
	"os"
	"time"

	"github.com/slackhq/nebula/cert"
)

type host struct {
	Name              string   `json:"name"`
	CertificateOutput string   `json:"certificateOutput"`
	PublicKey         string   `json:"publicKey"`
	CA                string   `json:"ca"`
	Networks          []string `json:"networks"`
	UnsafeNetworks    []string `json:"unsafeNetworks"`
	Groups            []string `json:"groups"`
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "usage: %s <hosts.json> <ca-key>\n", os.Args[0])
		os.Exit(2)
	}

	hosts, err := readHosts(os.Args[1])
	if err != nil {
		fail(err)
	}

	caKey, caKeyCurve, err := readCAKey(os.Args[2])
	if err != nil {
		fail(err)
	}

	for _, h := range hosts {
		if err := recertHost(h, caKey, caKeyCurve); err != nil {
			fail(fmt.Errorf("%s: %w", h.Name, err))
		}
		fmt.Printf("wrote %s\n", h.CertificateOutput)
	}
}

func fail(err error) {
	fmt.Fprintf(os.Stderr, "%v\n", err)
	os.Exit(1)
}

func readHosts(path string) ([]host, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read hosts: %w", err)
	}

	var hosts []host
	if err := json.Unmarshal(b, &hosts); err != nil {
		return nil, fmt.Errorf("failed to parse hosts: %w", err)
	}
	if len(hosts) == 0 {
		return nil, fmt.Errorf("no nebula hosts to recert")
	}

	for i, h := range hosts {
		if h.Name == "" {
			return nil, fmt.Errorf("host %d: missing name", i)
		}
		if h.CertificateOutput == "" {
			return nil, fmt.Errorf("%s: missing certificateOutput", h.Name)
		}
		if h.PublicKey == "" {
			return nil, fmt.Errorf("%s: missing publicKey", h.Name)
		}
		if h.CA == "" {
			return nil, fmt.Errorf("%s: missing ca", h.Name)
		}
		if len(h.Networks) == 0 {
			return nil, fmt.Errorf("%s: missing networks", h.Name)
		}
	}

	return hosts, nil
}

func readCAKey(path string) ([]byte, cert.Curve, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to read CA key %s: %w", path, err)
	}

	key, rest, curve, err := cert.UnmarshalSigningPrivateKeyFromPEM(b)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to parse CA key %s: %w", path, err)
	}
	if len(bytes.TrimSpace(rest)) > 0 {
		return nil, 0, fmt.Errorf("CA key %s contains extra data", path)
	}

	return key, curve, nil
}

func recertHost(h host, caKey []byte, caKeyCurve cert.Curve) error {
	caCert, err := readCertificate(h.CA)
	if err != nil {
		return err
	}
	if !caCert.IsCA() {
		return fmt.Errorf("%s is not a CA certificate", h.CA)
	}
	if caCert.Expired(time.Now()) {
		return fmt.Errorf("CA certificate %s is expired", h.CA)
	}
	if err := caCert.VerifyPrivateKey(caKeyCurve, caKey); err != nil {
		return fmt.Errorf("CA certificate %s does not match CA key", h.CA)
	}

	publicKey, publicKeyCurve, err := readPublicKey(h.PublicKey)
	if err != nil {
		return err
	}
	if publicKeyCurve != caKeyCurve {
		return fmt.Errorf("public key curve %s from %s does not match CA key curve %s", publicKeyCurve, h.PublicKey, caKeyCurve)
	}

	networks, err := parsePrefixes(h.Networks)
	if err != nil {
		return fmt.Errorf("invalid networks: %w", err)
	}
	unsafeNetworks, err := parsePrefixes(h.UnsafeNetworks)
	if err != nil {
		return fmt.Errorf("invalid unsafe networks: %w", err)
	}

	notBefore := time.Now()
	notAfter := caCert.NotAfter().Add(-time.Second)
	if !notAfter.After(notBefore) {
		return fmt.Errorf("CA certificate %s expires too soon", h.CA)
	}

	t := &cert.TBSCertificate{
		Version:        caCert.Version(),
		Name:           h.Name,
		Networks:       networks,
		UnsafeNetworks: unsafeNetworks,
		Groups:         h.Groups,
		IsCA:           false,
		NotBefore:      notBefore,
		NotAfter:       notAfter,
		PublicKey:      publicKey,
		Curve:          caKeyCurve,
	}

	c, err := t.Sign(caCert, caKeyCurve, caKey)
	if err != nil {
		return fmt.Errorf("failed to sign certificate: %w", err)
	}

	pem, err := c.MarshalPEM()
	if err != nil {
		return fmt.Errorf("failed to marshal certificate: %w", err)
	}
	if err := os.WriteFile(h.CertificateOutput, pem, 0600); err != nil {
		return fmt.Errorf("failed to write certificate %s: %w", h.CertificateOutput, err)
	}

	return nil
}

func readCertificate(path string) (cert.Certificate, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read CA certificate %s: %w", path, err)
	}

	c, rest, err := cert.UnmarshalCertificateFromPEM(b)
	if err != nil {
		return nil, fmt.Errorf("failed to parse CA certificate %s: %w", path, err)
	}
	if len(bytes.TrimSpace(rest)) > 0 {
		return nil, fmt.Errorf("CA certificate %s contains extra data", path)
	}
	return c, nil
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

func parsePrefixes(values []string) ([]netip.Prefix, error) {
	prefixes := make([]netip.Prefix, 0, len(values))
	for _, value := range values {
		prefix, err := netip.ParsePrefix(value)
		if err != nil {
			return nil, fmt.Errorf("%q: %w", value, err)
		}
		prefixes = append(prefixes, prefix)
	}
	return prefixes, nil
}
