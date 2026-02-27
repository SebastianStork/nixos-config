{ self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  custom = {
    boot.loader.systemd-boot.enable = true;

    networking = {
      overlay = {
        address = "10.254.250.2";
        isLighthouse = true;
      };
      underlay = {
        interface = "enp1s0";
        cidr = "49.13.231.235/32";
        isPublic = true;
        gateway = "172.31.1.1";
      };
    };

    services.dns.enable = true;
  };
}
