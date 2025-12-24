_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.install-anywhere = pkgs.writeShellApplication {
        name = "install-anywhere";

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
          root="/tmp/anywhere/$host"

          impermanence="$(nix eval ".#nixosConfigurations.$host.config.custom.persistence.enable")"
          if [ "$impermanence" = true ]; then
            ssh_dir="$root/persist/etc/ssh"
          else
            ssh_dir="$root/etc/ssh"
          fi

          if [ ! -f "$ssh_dir/ssh_host_ed25519_key" ]; then
            echo "==> Generating new SSH host keys..."
            mkdir --parents "$ssh_dir"
            ssh-keygen -C "root@$host" -f "$ssh_dir/ssh_host_ed25519_key" -N "" -q

            echo "==> Replacing old age key with new age key..."
            new_age_key="$(ssh-to-age -i "$ssh_dir/ssh_host_ed25519_key.pub")"
            sed -i -E "s|(agePublicKey\s*=\s*\")[^\"]*(\";)|\1$new_age_key\2|" "hosts/$host/default.nix"

            echo "==> Updating SOPS secrets..."
            if BW_SESSION="$(bw unlock --raw || bw login --raw)"; then
              export BW_SESSION
            fi
            SOPS_AGE_KEY="$(bw get notes 'admin age-key')"
            export SOPS_AGE_KEY
            SOPS_CONFIG="$(nix build .#sops-config --print-out-paths)"
            export SOPS_CONFIG
            sops updatekeys --yes "hosts/$host/secrets.json"
          fi

          echo "==> Installing system..."
          nix run github:nix-community/nixos-anywhere -- \
            --extra-files "$root" \
            --flake ".#$host" \
            --target-host "$destination"
        '';
      };
    };
}
