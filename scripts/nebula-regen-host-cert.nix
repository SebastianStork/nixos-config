{ pkgs }:
pkgs.writeShellApplication {
  name = "nebula-regen-host-cert";

  runtimeInputs = [
    pkgs.nebula
    pkgs.bitwarden-cli
  ];

  text = ''
    if [[ $# -ne 1 ]]; then
      echo "Usage: $0 <host>"
      exit 1
    fi

    host="$1"
    address="$(nix eval --raw ".#nixosConfigurations.$host.config.custom.networking.overlay.cidr")"
    ca_cert='modules/system/services/nebula/ca.crt'
    host_pub="$(nix eval --raw ".#nixosConfigurations.$host.config.custom.services.nebula.publicKeyPath")"
    host_cert="$(nix eval --raw ".#nixosConfigurations.$host.config.custom.services.nebula.certificatePath")"
    host_cert="''${host_cert#*-source/}"

    if ! declare -px BW_SESSION >/dev/null 2>&1; then
      BW_SESSION="$(bw unlock --raw || bw login --raw)"
      export BW_SESSION
    fi

    ca_key="$(mktemp)"
    chmod 600 "$ca_key"
    trap 'rm -f "$ca_key"' EXIT
    bw get notes 'nebula ca-key' > "$ca_key"

    rm -f "$host_cert"
    nebula-cert sign -name "$host" -networks "$address" -ca-crt "$ca_cert" -ca-key "$ca_key" -in-pub "$host_pub" -out-crt "$host_cert"
  '';
}
