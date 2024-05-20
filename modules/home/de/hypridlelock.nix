{
  config,
  pkgs,
  lib,
  wrappers,
  ...
}:
{
  options.myConfig.de.hypridlelock.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.hypridlelock.enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd =
            let
              hyprlockExe = "${lib.getExe wrappers.hyprlock}";
            in
            "pidof ${hyprlockExe} || ${hyprlockExe}";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "${lib.getExe pkgs.brightnessctl} -s && ${lib.getExe pkgs.brightnessctl} -e set 10%";
            on-resume = "${lib.getExe pkgs.brightnessctl} -r";
          }
          {
            timeout = 600;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 610;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
}
