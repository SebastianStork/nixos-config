_: {
  perSystem =
    { self', pkgs, ... }:
    {
      devShells = {
        sops = pkgs.mkShellNoCC {
          packages = [
            pkgs.sops
            pkgs.age
            pkgs.ssh-to-age
            pkgs.bitwarden-cli
          ];

          shellHook = ''
            if ! declare -px BW_SESSION >/dev/null 2>&1; then
              BW_SESSION="$(bw unlock --raw || bw login --raw)"
              export BW_SESSION
            fi
            if ! declare -px SOPS_AGE_KEY >/dev/null 2>&1; then
              SOPS_AGE_KEY="$(bw get notes 'admin age-key')"
              export SOPS_AGE_KEY
            fi
            SOPS_CONFIG="${self'.packages.sops-config}"
            export SOPS_CONFIG
          '';
        };

        nebula = pkgs.mkShellNoCC {
          packages = [
            pkgs.nebula
            pkgs.bitwarden-cli
            self'.packages.nebula-regen-host-cert
            self'.packages.nebula-regen-all-host-certs
          ];

          shellHook = ''
            if ! declare -px BW_SESSION >/dev/null 2>&1; then
              BW_SESSION="$(bw unlock --raw || bw login --raw)"
              export BW_SESSION
            fi
          '';
        };
      };
    };
}
