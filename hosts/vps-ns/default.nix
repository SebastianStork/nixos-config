{ self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  custom = {
    boot.loader.grub.enable = true;

    networking = {
      overlay = {
        address = "10.254.250.5";
        isLighthouse = true;
      };
      underlay = {
        interface = "enp1s0";
        cidr = "188.245.223.145/32";
        isPublic = true;
        gateway = "172.31.1.1";
      };
    };

    services = {
      private-nameserver.enable = true;
      public-nameserver = {
        enable = true;
        zones = [
          "sprouted.cloud"
          "sstork.dev"
        ];
      };
    };
  };
}
