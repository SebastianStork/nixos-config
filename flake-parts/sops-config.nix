{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.sops-config =
        let
          adminPublicKey = "age1ftexg8phw860f06gg45tu4l480nqe7yw8cp2qkn4x88nmuj5cv0q95hpxc";

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
