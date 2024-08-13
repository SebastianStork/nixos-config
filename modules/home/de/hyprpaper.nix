{ config, lib, ... }:
{
  options.myConfig.de.hyprpaper.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.hyprpaper.enable {
    services.hyprpaper = {
      enable = true;

      settings = {
        preload = [ "~/Pictures/.wallpaper" ];
        wallpaper = [ ", ~/Pictures/.wallpaper" ];
      };
    };
  };
}
