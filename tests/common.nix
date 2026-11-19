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
    { config, containers, ... }:
    {
      imports = [ self.nixosModules.default ];
      _module.args.allHosts = containers |> lib.mapAttrs (_: container: { config = container; });

      users = {
        mutableUsers = false;
        users.seb = {
          isNormalUser = true;
          password = "seb";
        };
      };

      networking = {
        extraHosts = lib.mkForce "";
        useHostResolvConf = false;
      };

      custom.networking = {
        underlay.interface = "eth1";
        overlay.nebula = {
          caCertificateFile = "${testDir}/keys/nebula-ca.crt";
          certificateFile = "${testDir}/keys/${config.networking.hostName}/nebula.crt";
          privateKeyFile = "${testDir}/keys/${config.networking.hostName}/nebula.key";
        };
      };
    };
}
