{ self', pkgs, ... }:
pkgs.writeShellApplication {
  name = "nebula-recert-all-hosts";

  runtimeInputs = [
    pkgs.bitwarden-cli
    pkgs.jq
    self'.packages.nebula-recert-host
  ];

  text = ''
    hosts="$(nix eval .#nixosConfigurations --apply 'builtins.attrNames' --json | jq -r '.[]')"

    if ! declare -px BW_SESSION >/dev/null 2>&1; then
      BW_SESSION="$(bw unlock --raw || bw login --raw)"
      export BW_SESSION
    fi

    ca_key="$(mktemp)"
    chmod 600 "$ca_key"
    trap 'rm -f "$ca_key"' EXIT
    bw get notes 'nebula ca-key' > "$ca_key"

    for host in $hosts; do
      echo "Regenerating certificate for $host..."
      nebula-recert-host "$host" "$ca_key"
    done

    echo "Done!"
  '';
}
