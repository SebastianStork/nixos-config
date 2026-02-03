{ self, ... }:
{
  imports = [ self.nixosModules.profile-workstation ];

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

    services = {
      bluetooth.enable = true;
      syncthing.deviceId = "Q4YPD3V-GXZPHSN-PT5X4PU-FBG4GX2-IASBX75-7NYMG75-4EJHBMZ-4WGDDAP";
    };

    programs = {
      winboat.enable = true;
      wireshark.enable = true;
    };
  };
}
