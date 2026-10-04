{
  config,
  osConfig,
  inputs,
  pkgs-unstable,
  lib,
  ...
}:
{
  imports = [ "${inputs.home-manager-unstable}/modules/programs/noctalia/default.nix" ];

  options.custom.programs.noctalia.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.noctalia.enable {
    programs.noctalia = {
      enable = true;
      package = pkgs-unstable.noctalia;
      systemd.enable = true;
      settings = {
        shell = {
          avatar_path = "/home/seb/Pictures/face";
          clipboard_auto_paste = "off";
          telemetry_enabled = false;
          animation.speed = 1.8;
          panel = {
            borders = true;
            shadow = false;
          };
          launcher = {
            categories = false;
            providers = {
              session.global = false;
              windows.global = false;
            };
          };
          mpris.blacklist = [ "firefox" ];
          session = {
            grid = false;
            actions =
              [
                "lock"
                "logout"
                "lock_and_suspend"
                "reboot"
                "shutdown"
              ]
              |> lib.map (action: {
                inherit action;
                countdown_seconds = 3;
              });
          };
        };
        lockscreen = {
          blur_intensity = 0.0;
          fingerprint = true;
          tint_intensity = 0.0;
          transition = [ ];
        };
        wallpaper = {
          enabled = true;
          directory = "/home/seb/Pictures/Wallpapers";
          transition = [ "fade" ];
          transition_duration = 1000;
          automation = {
            enabled = true;
            interval_seconds = 1800;
            order = "random";
          };
        };
        theme = {
          mode =
            {
              dark = "dark";
              light = "light";
            }
            .${config.custom.theme};
          source = "community";
          community_palette = "GitHub Dark";
        };
        bar.main = {
          position = "bottom";
          capsule = true;
          capsule_padding = 8.0;
          concave_edge_corners = false;
          font_family = "Roboto";
          font_scale = 1.2;
          font_weight = 400;
          margin_ends = 0;
          radius = 0;
          widget_spacing = 10;
          shadow = false;
          start = [ "clock" ];
          center = [ "workspaces" ];
          end = [
            "tray"
            "notifications"
            "volume"
          ]
          ++ lib.optional osConfig.custom.services.bluetooth.enable "bluetooth"
          ++ lib.optional config.custom.programs.brightnessctl.enable "brightness"
          ++ [ "battery" ];
        };
        widget = {
          clock = {
            format = "{:%H:%M %a, %-d %b}";
            tooltip_format = "{:%H:%M %Y-%m-%d}";
          };
          notifications.hide_when_no_unread = true;
        };
        audio.enable_sounds = false;
        dock.enabled = false;
        osd.kinds.media = false;
        idle.behavior = {
          lock.enabled = false;
          screen-off.enabled = false;
        };
        location.address = "Darmstadt";
        control_center.calendar.show_week_numbers = true;
      };
    };
  };
}
