{ config, lib, ... }:
{
  options.custom.deUtils.services.hyprpaper.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.deUtils.services.hyprpaper.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [ "~/Pictures/.wallpaper" ];
        wallpaper = [ ", ~/Pictures/.wallpaper" ];
      };
    };
  };
}
