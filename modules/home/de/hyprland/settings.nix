{ config, lib, ... }:
{
  config = lib.mkIf config.myConfig.de.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      input = {
        kb_layout = "de";
        kb_variant = "nodeadkeys";
        accel_profile = "flat";
      };

      device = [
        {
          name = "logitech-usb-receiver-mouse";
          sensitivity = "0.2";
        }
        {
          name = "dell0b9f:00-27c6:0d43-touchpad";
          accel_profile = "adaptive";
          disable_while_typing = true;
          natural_scroll = true;
          middle_button_emulation = true;
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
          .${config.myConfig.de.theme};
        "col.inactive_border" =
          {
            dark = "rgba(ffffff00)";
            light = "rgba(ffffff00)";
          }
          .${config.myConfig.de.theme};
        layout = "master";
      };

      master = {
        no_gaps_when_only = 1;
        mfact = "0.5";
      };

      decoration = {
        rounding = 6;
        drop_shadow = false;
      };

      animations.enabled = false;

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        key_press_enables_dpms = true;
      };

      workspace = [
        "special:music, border:false, gapsout:30, on-created-empty:spotify"
        "special:chat, border:false, gapsout:30, on-created-empty:webcord"
        "special:flake, border:false, gapsout:30, on-created-empty:kitty --directory ${config.home.sessionVariables.FLAKE}"
        "special:monitor, border:false, gapsout:30, on-created-empty:kitty btm"
        "special:files, border:false, gapsout:30, on-created-empty:nemo"
      ];
      windowrulev2 = [ "noblur, class:(kitty), onworkspace:special:flake" ];
      exec-once = [
        "[workspace special:music silent] spotify"
        "[workspace special:chat silent] webcord"
      ];
    };
  };
}
