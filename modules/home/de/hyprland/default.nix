{
  config,
  pkgs,
  lib,
  ...
}@moduleArgs:
{
  options.myConfig.de.hyprland.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.myConfig.de.hyprland.enable or false;
  };

  config = lib.mkIf config.myConfig.de.hyprland.enable {
    wayland.windowManager.hyprland.enable = true;

    home.packages = [
      pkgs.wl-clipboard
      pkgs.playerctl
      pkgs.brightnessctl
      pkgs.grimblast
    ];

    myConfig.de = {
      rofi.enable = true;
      hyprpaper.enable = true;
      hyprlock.enable = true;
      hypridle.enable = true;
      waybar.enable = true;
      cliphist.enable = true;
      gammastep.enable = true;
    };

    services.dunst.enable = true;
  };
}
