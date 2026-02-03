{ self, ... }:
{
  imports = [ self.nixosModules.profile-workstation ];

  system.stateVersion = "23.11";

  custom = {
    boot.loader.systemd-boot.enable = true;

    networking = {
      overlay.address = "10.254.250.1";
      underlay = {
        interface = "enp6s0";
        useDhcp = true;
      };
    };

    services.syncthing.deviceId = "FAJS5WM-UAWGW2U-FXCGPSP-VAUOTGM-XUKSEES-D66PMCJ-WBODJLV-XTNCRA7";

    programs.steam.enable = true;
  };
}
