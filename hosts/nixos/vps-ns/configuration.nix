{ config, self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  custom = {
    boot.loader.grub.enable = true;

    networking = {
      overlay = {
        address = "10.254.250.5";
        isLighthouse = true;
        isExitNode = true;
      };
      underlay = {
        interface = "enp1s0";
        cidr = "188.245.223.145/32";
        isPublic = true;
        gateway = "172.31.1.1";
      };
    };

    services = {
      blocking-nameserver = {
        enable = true;
        gui.domain = "adguard.${config.custom.networking.overlay.fqdn}";
      };
      recursive-nameserver = {
        enable = true;
        serveAuthoritatively = true;
      };
      public-nameserver = {
        enable = true;
        publicHostName = "ns1";
        zones = [
          "sprouted.cloud"
          "sstork.dev"
        ];
      };
    };
  };
}
