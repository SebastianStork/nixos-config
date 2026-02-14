{ pkgs, ... }:
{
  runtimeInputs = [
    pkgs.sops
    pkgs.ssh-to-age
    pkgs.bitwarden-cli
  ];

  text = ''
    if [[ $# -ne 2 ]]; then
      echo "Usage: $0 <host> <destination>"
      exit 1
    fi

    host="$1"
    destination="$2"
    root="$(mktemp --directory)"
    trap 'rm -rf "$root"' EXIT

    impermanence="$(nix eval ".#nixosConfigurations.$host.config.custom.persistence.enable")"
    if [ "$impermanence" = true ]; then
      ssh_dir="$root/persist/etc/ssh"
    else
      ssh_dir="$root/etc/ssh"
    fi

    echo "==> Generating new SSH host keys..."
    mkdir --parents "$ssh_dir"
    ssh-keygen -C "root@$host" -f "$ssh_dir/ssh_host_ed25519_key" -N "" -q

    echo "==> Replacing old age key with new age key..."
    new_age_key="$(ssh-to-age -i "$ssh_dir/ssh_host_ed25519_key.pub")"
    echo "$new_age_key" > "hosts/$host/keys/age.pub"

    echo "==> Updating SOPS secrets..."
    if ! declare -px BW_SESSION >/dev/null 2>&1; then
      BW_SESSION="$(bw unlock --raw || bw login --raw)"
      export BW_SESSION
    fi
    if ! declare -px SOPS_AGE_KEY >/dev/null 2>&1; then
      SOPS_AGE_KEY="$(bw get notes 'admin age-key')"
      export SOPS_AGE_KEY
    fi
    SOPS_CONFIG="$(nix build .#sops-config --print-out-paths)"
    export SOPS_CONFIG
    sops updatekeys --yes "hosts/$host/secrets.json"

    echo "==> Installing system..."
    nix run github:nix-community/nixos-anywhere -- \
      --extra-files "$root" \
      --flake ".#$host" \
      --target-host "$destination"
  '';
}
