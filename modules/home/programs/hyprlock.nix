{ config, lib, ... }@moduleArgs:
let
  cfg = config.custom.programs.hyprlock;
in
{
  options.custom.programs.hyprlock = {
    enable = lib.mkEnableOption "";
    fprintAuth = lib.mkEnableOption "" // {
      default = moduleArgs.osConfig.services.fprintd.enable or false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;

      settings = {
        general.immediate_render = true;
        auth."fingerprint:enabled" = cfg.fprintAuth;

        animations.enabled = false;
        input-field.monitor = "";
        background = {
          monitor = "";
          path = "~/Pictures/.wallpaper";
          color = "rgb(0,0,0)";
          blur_size = 4;
          blur_passes = 1;
        };
      };
    };
  };
}
