{ self, ... }:
{
  imports = [ self.nixosModules.workstation-profile ];

  system.stateVersion = "24.11";

  custom = {
    boot.loader.systemd-boot.enable = true;

    networking = {
      overlay.address = "10.254.250.3";
      underlay = {
        interface = "wlan0";
        useDhcp = true;
        wireless.enable = true;
      };
    };

    services.bluetooth.enable = true;

    programs = {
      winboat.enable = true;
      wireshark.enable = true;
    };
  };
}
