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
          adminKey = "age1mpq8m4p7dnxh5ze3fh7etd2k6sp85zdnmp9te3e9chcw4pw07pcq960zh5";

          mkCreationRule = sopsCfg: {
            path_regex = sopsCfg.secretsFile;
            key_groups = lib.singleton {
              age = [
                adminKey
                sopsCfg.agePublicKey
              ];
            };
          };

          hostCreationRules =
            self.nixosConfigurations
            |> lib.filterAttrs (_: value: value.config.custom.sops.enable or false)
            |> lib.mapAttrsToList (_: value: mkCreationRule value.config.custom.sops);

          userCreationRules =
            self.nixosConfigurations
            |> lib.filterAttrs (_: value: value.config.home-manager.users.seb.custom.sops.enable or false)
            |> lib.mapAttrsToList (_: value: mkCreationRule value.config.home-manager.users.seb.custom.sops);

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

        nativeBuildInputs = [
          pkgs.bitwarden-cli
          pkgs.jq
        ];
        shellHook = ''
          if BW_SESSION="$(bw login --raw)"; then
            export BW_SESSION
          fi
          SOPS_AGE_KEY="$(bw get item 'admin age-key' | jq -r '.notes')"
          export SOPS_AGE_KEY
          SOPS_CONFIG="${self'.packages.sops-config}"
          export SOPS_CONFIG
        '';
      };
    };
}
