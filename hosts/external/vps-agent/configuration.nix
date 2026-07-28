{ self, lib, ... }:
{
  imports = [ self.nixosModules.default ];

  nixpkgs.hostPlatform = "x86_64-linux";

  custom = {
    networking = {
      overlay = {
        address = "10.254.250.7";
        role = "agent";
      };
      underlay = {
        interface = "enp1s0";
        cidr = "167.235.73.246/32";
        isPublic = true;
        gateway = "172.31.1.1";
      };
    };

    services.nebula = {
      publicKeyFile = lib.toString ./keys/nebula.pub;
      certificateFile = lib.toString ./keys/nebula.crt;
    };
  };
}
