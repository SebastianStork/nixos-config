{
  config,
  pkgs,
  lib,
  wrappers,
  ...
}@moduleArgs:
{
  options.myConfig.de.hyprland.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.myConfig.de.hyprland.enable or false;
  };

  config = lib.mkIf config.myConfig.de.hyprland.enable {
    home.packages = [
      wrappers.hyprpaper
      wrappers.waybar
      wrappers.hypridle
      (wrappers.rofi { inherit (config.myConfig) theme; })
      pkgs.cliphist
      pkgs.wl-clipboard
      (pkgs.writeScriptBin "clipboard" "cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy")
      pkgs.playerctl
      pkgs.brightnessctl
      pkgs.grimblast
    ];

    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        exec-once = [
          "hyprpaper"
          "sleep 3 && waybar"
          "hypridle"
          "cliphist wipe && wl-paste --watch cliphist store"
        ];

        input = {
          kb_layout = "de";
          kb_variant = "nodeadkeys";
          accel_profile = "flat";
        };

        device = {
          name = "dell0b9f:00-27c6:0d43-touchpad";
          accel_profile = "adaptive";
          disable_while_typing = true;
          natural_scroll = true;
          middle_button_emulation = true;
        };

        gestures.workspace_swipe = true;

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 1;
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
      };
    };
  };
}
