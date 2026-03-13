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
            { config, nodes, ... }:
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

              networking.extraHosts = lib.mkForce "";
              custom = {
                networking.underlay.interface = "eth1";
                services.nebula = {
                  caCertificateFile = "${self}/tests/${dir}/keys/nebula-ca.crt";
                  certificateFile = "${self}/tests/${dir}/keys/${config.networking.hostName}/nebula.crt";
                  privateKeyFile = "${self}/tests/${dir}/keys/${config.networking.hostName}/nebula.key";
                };
              };
            };
        };
      };
    in
    {
      checks = "${self}/tests" |> self.lib.listDirectoryNames |> lib.map mkTest |> lib.listToAttrs;
    };
}
