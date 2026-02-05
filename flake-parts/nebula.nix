_: {
  perSystem =
    { self', pkgs, ... }:
    {
      devShells.nebula = pkgs.mkShellNoCC {
        packages = [
          pkgs.nebula
          pkgs.bitwarden-cli
          self'.packages.nebula-regen-host-cert
        ];

        shellHook = ''
          if ! declare -px BW_SESSION >/dev/null 2>&1; then
            BW_SESSION="$(bw unlock --raw || bw login --raw)"
            export BW_SESSION
          fi
        '';
      };
    };
}
