{ config, lib, ... }:
{
  options.myConfig.de.hyprlock.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.hyprlock.enable {
    programs.hyprlock = {
      enable = true;

      settings = {
        general.no_fade_in = true;
        background = {
          monitor = "";
          path = "~/Pictures/.wallpaper";
          blur_size = 4;
          blur_passes = 1;
        };
        input-field.monitor = "";
      };
    };
  };
}
