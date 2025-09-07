_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.provision-keys = pkgs.writeShellApplication {
        name = "provision-keys";

        runtimeInputs = [
          pkgs.sops
          pkgs.ssh-to-age

          pkgs.bitwarden-cli
          pkgs.jq
        ];

        excludeShellChecks = [ "SC2155" ];

        text = ''
          if [[ $# -ne 1 ]]; then
            echo "Usage: $0 <host>"
            exit 1
          fi

          host="$1"

          impermanence=$(nixos-option --flake ".#$host" custom.impermanence.enable | awk '/^Value:/ {getline; print $1}')

          if [ "$impermanence" = "true" ]; then
            root="/tmp/anywhere/$host/persist"
          else
            root="/tmp/anywhere/$host"
          fi

          mkdir --parents "$root/etc/ssh"
          ssh-keygen -C "root@$host" -f "$root/etc/ssh/ssh_host_ed25519_key" -N "" -q

          new_age_key=$(ssh-to-age -i "$root/etc/ssh/ssh_host_ed25519_key.pub")

          # Replace old age key with new age key
          sed -i -E "s|(agePublicKey\s*=\s*\")[^\"]*(\";)|\1$new_age_key\2|" "hosts/$host/default.nix"

          export BW_SESSION=$(bw login | awk -F'"' '/export BW_SESSION/ {print $2}')
          export SOPS_AGE_KEY=$(bw get item 'admin age-key' | jq -r '.notes')
          export SOPS_CONFIG=$(nix build .#sops-config --print-out-paths)

          sops updatekeys --yes "hosts/$host/secrets.json"
        '';
      };
    };
}
