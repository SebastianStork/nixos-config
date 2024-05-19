{ pkgs, lib, ... }:
{
  imports = [ ./default.nix ];

  home-manager.users.seb = {
    home.packages = [
      pkgs.obs-studio
      pkgs.libsForQt5.kdenlive
      pkgs.gimp
    ];

    myConfig.de.theme = "dark";

    wayland.windowManager.hyprland.settings.monitor = "DP-2,2560x1440@144,0x0,1";

    services.hypridle.settings.general.before_sleep_cmd = lib.mkForce "";
  };
}
