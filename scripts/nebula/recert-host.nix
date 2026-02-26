{ pkgs, ... }:
{
  runtimeInputs = [
    pkgs.nebula
    pkgs.bitwarden-cli
  ];

  text = ''
    if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
      echo "Usage: $0 <hostname> [<ca-key-path>]"
      exit 1
    fi

    hostname="$1"
    address="$(nix eval --raw ".#allHosts.$hostname.config.custom.networking.overlay.cidr")"
    groups="$(nix eval --raw ".#allHosts.$hostname.config.custom.services.nebula.groups" --apply 'builtins.concatStringsSep ","')"
    ca_cert="$(nix eval --raw ".#allHosts.$hostname.config.custom.services.nebula.caCertificateFile")"
    host_pub="$(nix eval --raw ".#allHosts.$hostname.config.custom.services.nebula.publicKeyFile")"
    host_cert="$(nix eval --raw ".#allHosts.$hostname.config.custom.services.nebula.certificateFile")"
    host_cert="''${host_cert#*-source/}"

    if [[ $# -eq 2 ]]; then
      ca_key="$2"
    else
      if ! declare -px BW_SESSION >/dev/null 2>&1; then
        BW_SESSION="$(bw unlock --raw || bw login --raw)"
        export BW_SESSION
      fi

      ca_key="$(mktemp)"
      chmod 600 "$ca_key"
      trap 'rm -f "$ca_key"' EXIT
      bw get notes 'nebula ca-key' > "$ca_key"
    fi

    rm -f "$host_cert"
    nebula-cert sign \
      -name "$hostname" \
      -networks "$address" \
      -groups "$groups" \
      -ca-crt "$ca_cert" \
      -ca-key "$ca_key" \
      -in-pub "$host_pub" \
      -out-crt "$host_cert"
  '';
}
