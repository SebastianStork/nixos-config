{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.sops-config =
        let
          mkCreationRule = sopsCfg: {
            path_regex = self.lib.relativePath sopsCfg.secretsFile;
            key_groups = lib.singleton {
              age = [
                self.lib.adminAgePublicKey
                sopsCfg.agePublicKey
              ];
            };
          };

          hostCreationRules =
            self.allHosts
            |> lib.attrValues
            |> lib.map (host: host.config.custom.sops)
            |> lib.filter (sops: sops.enable)
            |> lib.map mkCreationRule;

          userCreationRules =
            self.allHosts
            |> lib.attrValues
            |> lib.filter (host: host.config |> lib.hasAttr "home-manager")
            |> lib.map (host: host.config.home-manager.users.seb.custom.sops)
            |> lib.filter (sops: sops.enable)
            |> lib.map mkCreationRule;

          jsonConfig = { creation_rules = hostCreationRules ++ userCreationRules; } |> lib.strings.toJSON;
        in
        pkgs.runCommand "sops.yaml" { buildInputs = [ pkgs.yj ]; } ''
          echo '${jsonConfig}' | yj -jy > $out
        '';
    };
}
