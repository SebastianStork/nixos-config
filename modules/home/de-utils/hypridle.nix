{
  config,
  lib,
  ...
}:
{
  options.custom.deUtils.services.hypridle.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.deUtils.services.hypridle.enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd = lib.mkIf config.custom.deUtils.programs.hyprlock.enable "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          (lib.mkIf config.custom.deUtils.programs.brightnessctl.enable {
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
