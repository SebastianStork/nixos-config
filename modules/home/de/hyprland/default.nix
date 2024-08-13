{
  config,
  pkgs,
  lib,
  wrappers,
  ...
}@moduleArgs:
{
  options.myConfig.de.hyprland.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.myConfig.de.hyprland.enable or false;
  };

  config = lib.mkIf config.myConfig.de.hyprland.enable {
    wayland.windowManager.hyprland.enable = true;

    home.packages = [
      (wrappers.rofi { inherit (config.myConfig) theme; })
      pkgs.wl-clipboard
      pkgs.playerctl
      pkgs.brightnessctl
      pkgs.grimblast
    ];

    myConfig.de = {
      hyprpaper.enable = true;
      hypridle.enable = true;
      waybar.enable = true;
      cliphist.enable = true;
    };

    services.dunst.enable = true;
  };
}
