{ pkgs, ... }:
{
  home.stateVersion = "23.11";

  custom.theme = "dark";

  home.packages = [ pkgs.ddcutil ];

  programs.noctalia.settings.brightness = {
    enable_ddcutil = true;
    monitor."DP-1".backend = "ddcutil";
  };

  wayland.windowManager.hyprland.settings.monitor = [ "DP-1,2560x1440@180,0x0,1" ];
}
