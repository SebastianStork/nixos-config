{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.deUtils.hypridle.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.deUtils.hypridle.enable {
    home.packages = [ pkgs.brightnessctl ];

    services.hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "brightnessctl --save --exponent set 10%";
            on-resume = "brightnessctl --restore";
          }
          {
            timeout = 600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 610;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 1800;
            on-timeout = "systemctl sleep";
          }
        ];
      };
    };
  };
}
