{ config, lib, ... }:
{
  options.myConfig.deUtils.hyprpaper.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.deUtils.hyprpaper.enable {
    services.hyprpaper = {
      enable = true;

      settings = {
        preload = [ "~/Pictures/.wallpaper" ];
        wallpaper = [ ", ~/Pictures/.wallpaper" ];
      };
    };
  };
}
