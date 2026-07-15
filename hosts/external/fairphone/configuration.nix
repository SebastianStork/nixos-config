{ self, lib, ... }:
{
  imports = [ self.nixosModules.default ];

  nixpkgs.hostPlatform = "x86_64-linux";

  custom = {
    networking = {
      overlay = {
        address = "10.254.250.74";
        role = "client";
      };
      underlay.useDhcp = true;
    };

    services = {
      nebula = {
        publicKeyFile = lib.toString ./keys/nebula.pub;
        certificateFile = lib.toString ./keys/nebula.crt;
      };

      syncthing = {
        enable = true;
        deviceId = "6ROH65D-E65I5F6-URI4OUZ-RCHFC3B-PMBSIHH-5DNLJPS-SYSUWQY-HKYGHQG";
        folders = [ "Documents" ];
      };
    };
  };
}
