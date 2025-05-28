{ config, lib, ... }:
{
  options.custom.services.hyprpaper.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.hyprpaper.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [ "~/Pictures/.wallpaper" ];
        wallpaper = [ ", ~/Pictures/.wallpaper" ];
      };
    };
  };
}
