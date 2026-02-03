{ self, pkgs, ... }:
{
  imports = [ self.nixosModules.profile-core ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  custom = {
    networking.overlay.role = "client";
    boot.silent = true;
    dm.tuigreet = {
      enable = true;
      autoLogin = true;
    };
    de.hyprland.enable = true;
    services = {
      sound.enable = true;
      syncthing.enable = true;
    };
  };

  programs.localsend.enable = true;
}
