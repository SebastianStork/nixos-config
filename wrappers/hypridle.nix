{ inputs, pkgs, ... }:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.hypridle = {
        basePackage = pkgs.hypridle;
        flags =
          let
            hypridle-config = pkgs.writeText "hypridle-config" ''
              general {
                lock_cmd = pidof hyprlock || hyprlock
                before_sleep_cmd = loginctl lock-session
                after_sleep_cmd = hyprctl dispatch dpms on
              }
              listener {
                timeout = 300
                on-timeout= brightnessctl -s && brightnessctl -e set 10%
                on-resume = brightnessctl -r
              }
              listener {
                timeout = 600
                on-timeout = loginctl lock-session
              }
              listener {
                timeout = 610
                on-timeout = hyprctl dispatch dpms off
                on-resume = hyprctl dispatch dpms on
              }
            '';
          in
          [
            "--config"
            hypridle-config
          ];
      };
    }
  ];
}).config.wrappers.hypridle.wrapped
