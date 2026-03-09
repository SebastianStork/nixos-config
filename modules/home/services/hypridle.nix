{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.services.hypridle;
in
{
  options.custom.services.hypridle = {
    enable = lib.mkEnableOption "";
    lockCommand = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      package = pkgs-unstable.hypridle;

      settings = {
        general = {
          lock_cmd = cfg.lockCommand;
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          (lib.mkIf config.custom.programs.brightnessctl.enable {
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
