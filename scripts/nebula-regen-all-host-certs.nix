{ self', pkgs, lib, ... }:
pkgs.writeShellApplication {
  name = "nebula-regen-all-host-certs";

  runtimeInputs = [
    pkgs.bitwarden-cli
    pkgs.jq
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
      ${lib.getExe self'.packages.nebula-regen-host-cert} "$host" "$ca_key"
    done

    echo "Done!"
  '';
}
