{ inputs, self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      mkTest = dir: rec {
        name = "${dir}-test";
        value = pkgs.testers.runNixOSTest {
          inherit name;
          imports = [ "${self}/tests/${dir}" ];
          node.specialArgs = { inherit inputs self; };
          defaults =
            { nodes, ... }:
            {
              imports = [ self.nixosModules.default ];
              _module.args.allHosts = nodes |> lib.mapAttrs (_: node: { config = node; });
              users = {
                mutableUsers = false;
                users.seb = {
                  isNormalUser = true;
                  password = "seb";
                };
              };
              custom.networking.underlay.interface = "eth1";
            };
        };
      };
    in
    {
      checks = "${self}/tests" |> self.lib.listDirectoryNames |> lib.map mkTest |> lib.listToAttrs;
    };
}
