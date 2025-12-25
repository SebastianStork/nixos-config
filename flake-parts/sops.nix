{ self, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:
    {
      packages.sops-config =
        let
          adminPublicKey = "age1mpq8m4p7dnxh5ze3fh7etd2k6sp85zdnmp9te3e9chcw4pw07pcq960zh5";

          mkCreationRule = sopsCfg: {
            path_regex = self.lib.relativePath sopsCfg.secretsFile;
            key_groups = lib.singleton {
              age = [
                adminPublicKey
                sopsCfg.agePublicKey
              ];
            };
          };

          hostCreationRules =
            self.nixosConfigurations
            |> lib.attrValues
            |> lib.filter (value: value.config.custom.sops.enable or false)
            |> lib.map (value: mkCreationRule value.config.custom.sops);

          userCreationRules =
            self.nixosConfigurations
            |> lib.attrValues
            |> lib.filter (value: value.config.home-manager.users.seb.custom.sops.enable or false)
            |> lib.map (value: mkCreationRule value.config.home-manager.users.seb.custom.sops);

          jsonConfig = { creation_rules = hostCreationRules ++ userCreationRules; } |> lib.strings.toJSON;
        in
        pkgs.runCommand "sops.yaml" { buildInputs = [ pkgs.yj ]; } ''
          echo '${jsonConfig}' | yj -jy > $out
        '';

      devShells.sops = pkgs.mkShellNoCC {
        packages = [
          pkgs.sops
          pkgs.age
          pkgs.ssh-to-age
        ];

        nativeBuildInputs = [ pkgs.bitwarden-cli ];
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
    };
}
