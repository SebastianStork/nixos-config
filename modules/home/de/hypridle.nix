{
  config,
  pkgs,
  lib,
  wrappers,
  ...
}:
{
  options.myConfig.de.hypridle.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.hypridle.enable {
    home.packages = [
      wrappers.hyprlock
      pkgs.brightnessctl
      (pkgs.writeScriptBin "lock-suspend" "loginctl lock-session && sleep 0.5 && systemctl suspend-then-hibernate")
    ];

    services.hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "brightnessctl -s && brightnessctl -e set 10%";
            on-resume = "brightnessctl -r";
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
            on-timeout = "lock-suspend";
          }
        ];
      };
    };
  };
}
