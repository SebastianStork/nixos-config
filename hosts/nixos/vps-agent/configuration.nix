{ self, ... }:
{
  imports = [ self.nixosModules.core-profile ];

  system.stateVersion = "26.05";

  custom = {
    persistence.enable = true;
    boot.loader.systemd-boot.enable = true;

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

    services.alloy.enable = true;
  };
}
