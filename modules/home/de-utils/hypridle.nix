{
  config,
  lib,
  ...
}:
{
  options.myConfig.deUtils.hypridle.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.deUtils.hypridle.enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd = lib.mkIf config.myConfig.deUtils.hyprlock.enable "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          (lib.mkIf config.myConfig.deUtils.brightnessctl.enable {
            timeout = 5 * 60;
            on-timeout = "brightnessctl --save --exponent set 10%";
            on-resume = "brightnessctl --restore";
          })
          {
            timeout = 10 * 60;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 10 * 60 + 10;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 30 * 60;
            on-timeout = "systemctl sleep";
          }
        ];
      };
    };
  };
}
