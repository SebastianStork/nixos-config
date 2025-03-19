{ config, lib, ... }:
{
  config = lib.mkIf config.myConfig.de.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      input = {
        kb_layout = "de";
        kb_variant = "nodeadkeys";
        accel_profile = "flat";

        touchpad = {
          disable_while_typing = true;
          natural_scroll = true;
          middle_button_emulation = true;
        };
      };

      device = [
        {
          name = "logitech-usb-receiver-mouse";
          sensitivity = "0.2";
        }
        {
          name = "pixa3854:00-093a:0274-touchpad";
          accel_profile = "adaptive";
        }
      ];

      gestures.workspace_swipe = true;

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" =
          {
            dark = "rgb(ffffff)";
            light = "rgb(000000)";
          }
          .${config.myConfig.theme};
        "col.inactive_border" =
          {
            dark = "rgba(ffffff00)";
            light = "rgba(ffffff00)";
          }
          .${config.myConfig.theme};
        layout = "master";
      };

      master.mfact = "0.5";

      decoration = {
        rounding = 6;
        shadow.enabled = false;
      };

      animations.enabled = false;

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        key_press_enables_dpms = true;
      };

      workspace = [
        # No gaps when only one
        "w[tv1], gapsout:0, gapsin:0"
        "f[1], gapsout:0, gapsin:0"

        "special:music, gapsout:30, on-created-empty:spotify"
        "special:chat, gapsout:30, on-created-empty:discord"
        "special:flake, gapsout:30, on-created-empty:kitty --directory ${config.home.sessionVariables.FLAKE}"
        "special:monitor, gapsout:30, on-created-empty:kitty btm"
        "special:files, gapsout:30, on-created-empty:nemo"
      ];
      windowrulev2 = [
        # No gaps when only one
        "bordersize 0, floating:0, onworkspace:w[tv1]"
        "rounding 0, floating:0, onworkspace:w[tv1]"
        "bordersize 0, floating:0, onworkspace:f[1]"
        "rounding 0,  floating:0, onworkspace:f[1]"

        "rounding 6, floating:0, onworkspace:special:music"
        "rounding 6, floating:0, onworkspace:special:chat"
        "rounding 6, floating:0, onworkspace:special:monitor"
        "rounding 6, floating:0, onworkspace:special:files"
        "rounding 6, floating:0, onworkspace:special:flake"
        "noblur, class:(kitty), onworkspace:special:flake"

        "idleinhibit fullscreen, class:.*"
      ];
      exec-once = [
        "[workspace special:music silent] spotify"
        "[workspace special:chat silent] discord"
      ];
    };
  };
}
