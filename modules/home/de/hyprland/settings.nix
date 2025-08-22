{ config, lib, ... }:
{
  config = lib.mkIf config.custom.de.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      input = {
        kb_layout = "de";
        kb_variant = "nodeadkeys";
        accel_profile = "flat";

        touchpad = {
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
            dark = "rgb(ffffff)"; # White
            light = "rgb(000000)"; # Black
          }
          .${config.custom.theme};
        "col.inactive_border" =
          {
            dark = "rgba(ffffff00)"; # Transparent
            light = "rgba(ffffff00)"; # Transparent
          }
          .${config.custom.theme};
        layout = "master";
      };

      master.mfact = "0.5";

      decoration = {
        rounding = 6;
        blur.enabled = false;
        shadow.enabled = false;
      };

      animations.enabled = false;

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        key_press_enables_dpms = true;
      };

      binds.hide_special_on_workspace_change = true;

      workspace = [
        # No outer gaps when only one tiled window on normal workspaces
        "w[t1]s[false], gapsout:0"
        # Large outer gaps on special workspaces
        "s[true], gapsout:30"

        "special:music, on-created-empty:spotify"
        "special:chat, on-created-empty:discord"
        "special:flake, on-created-empty:kitty --directory ${config.home.sessionVariables.NH_FLAKE}"
        "special:monitor, on-created-empty:kitty btm"
        "special:files, on-created-empty:nemo"
      ];
      windowrule = [
        # No borders on floating window when it's the only window
        "bordersize 0, floating:1, onworkspace:w[1]"
        # No borders on tiled window when it's the only tiled window
        "bordersize 0, floating:0, onworkspace:w[t1]"
        # No rounding on tiled window when it's the only tiled window on a normal workspace
        "rounding 0, floating:0, onworkspace:w[t1]s[false]"

        "idleinhibit fullscreen, class:.*"
      ];
    };
  };
}
