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

    programs.steam.enable = true;
  };
}
