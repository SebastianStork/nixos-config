{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
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

          jsonConfig = { creation_rules = hostCreationRules ++ userCreationRules; } |> builtins.toJSON;
        in
        pkgs.runCommand "sops-config" { buildInputs = [ pkgs.yj ]; } ''
          mkdir $out
          echo '${jsonConfig}' | yj -jy > $out/sops.yaml
        '';
    };
}
