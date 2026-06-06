testDir:
{
  inputs,
  self,
  lib,
  ...
}:
{
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
          caCertificateFile = "${testDir}/keys/nebula-ca.crt";
          certificateFile = "${testDir}/keys/${config.networking.hostName}/nebula.crt";
          privateKeyFile = "${testDir}/keys/${config.networking.hostName}/nebula.key";
        };
      };
    };
}
