{ self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  custom = {
    boot.loader.grub.enable = true;

    networking = {
      overlay.address = "10.254.250.6";
      underlay = {
        interface = "enp2s0";
        cidr = "192.168.0.64/24";
        gateway = "192.168.0.1";
      };
    };

    services = {
      dns.enable = true;

      syncthing = {
        enable = true;
        isServer = true;
        gui.domain = "syncthing.nas.splitleaf.de";
      };
    };
  };
}
