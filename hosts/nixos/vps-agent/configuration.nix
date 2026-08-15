{ config, self, ... }:
{
  imports = [ self.nixosModules.core-profile ];

  system.stateVersion = "26.05";

  custom = {
    boot.loader.systemd-boot.enable = true;
    persistence.enable = true;
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

    services = {
      auto-gc.onlyCleanRoots = true;
      deploy-webhook.enable = true;
      alloy = {
        enable = true;
        domain = "alloy.${config.custom.networking.overlay.fqdn}";
      };
    };

    web-services.librespeed.enable = true;
  };
}
