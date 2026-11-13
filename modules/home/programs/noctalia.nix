{
  config,
  osConfig,
  inputs,
  self,
  pkgs-unstable,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.programs.noctalia;
in
{
  imports = [ "${inputs.home-manager-unstable}/modules/programs/noctalia/default.nix" ];

  options.custom.programs.noctalia = {
    enable = lib.mkEnableOption "";
    calendar = {
      enable = lib.mkEnableOption "" // {
        default = true;
      };
      radicaleUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default =
          allHosts
          |> lib.attrValues
          |> lib.map (host: host.config.custom.web-services.radicale)
          |> lib.filter (radicale: radicale.enable)
          |> lib.map (radicale: "https://${radicale.domain}/")
          |> self.lib.atMostOne "enabled Radicale instance";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.noctalia = {
          enable = true;
          package = pkgs-unstable.noctalia;
          systemd.enable = true;
          settings = {
            shell = {
              avatar_path = "/home/seb/Pictures/face";
              clipboard_auto_paste = "off";
              telemetry_enabled = false;
              font_family = "sans-serif";
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
              screenshot = {
                annotate = true;
                close_on_copy = false;
                close_on_save = false;
                directory = config.xdg.userDirs.extraConfig.SCREENSHOTS;
                save_to_file = false;
              };
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
              font_family = "sans-serif";
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
              ]
              ++ lib.optional osConfig.custom.services.bluetooth.enable "bluetooth"
              ++ lib.optional osConfig.custom.networking.underlay.wireless.enable "network"
              ++ [
                "volume"
                "brightness"
                "battery"
              ];
            };
            widget = {
              clock = {
                format = "{:%H:%M %a, %-d %b}";
                tooltip_format = "{:%H:%M %Y-%m-%d}";
              };
              notifications.hide_when_no_unread = true;
              bluetooth.hide_when_adapter_off = true;
              brightness.show_label = false;
              network.show_label = false;
              volume = {
                mute_color = "on_surface";
                show_label = false;
              };
              workspaces.font_weight = 600;
            };
            audio.enable_sounds = false;
            dock.enabled = false;
            osd.kinds.media = false;
            idle = {
              behavior_order = [
                "dim"
                "screen-off"
                "lock"
                "suspend"
              ];
              behavior = {
                dim = lib.mkIf config.custom.programs.brightnessctl.enable {
                  timeout = 5 * 60;
                  action = "command";
                  command = "brightnessctl --save --exponent set 10%";
                  resume_command = "brightnessctl --restore";
                };
                screen-off = {
                  timeout = 10 * 60;
                  action = "screen_off";
                };
                lock = {
                  timeout = 10 * 60 + 10;
                  action = "lock";
                };
                suspend = {
                  timeout = 30 * 60;
                  action = "lock_and_suspend";
                };
              };
            };
            location.address = "Darmstadt";
          };
        };
      }
      (lib.mkIf cfg.calendar.enable {
        sops = {
          secrets = {
            "calendar/radicale-password" = lib.mkIf (cfg.calendar.radicaleUrl != null) { };
            "calendar/stundenplan-url" = { };
          };
          templates."noctalia-calendar-ics.toml" = {
            path = "${config.xdg.configHome}/noctalia/calendar-ics.toml";
            content = ''
              [calendar.account.stundenplan]
              color = "primary"
              name = "Stundenplan"
              server_url = "${config.sops.placeholder."calendar/stundenplan-url"}"
              type = "ics"
            '';
          };
        };

        programs.noctalia.settings.calendar = {
          enabled = true;
          account = lib.mkIf (cfg.calendar.radicaleUrl != null) {
            seb = {
              color = "secondary";
              credential_source = "file";
              name = "Sebastian";
              password_file = config.sops.secrets."calendar/radicale-password".path;
              provider = "custom";
              server_url = cfg.calendar.radicaleUrl;
              type = "caldav";
              username = "seb";
            };
          };
        };
      })
    ]
  );
}
