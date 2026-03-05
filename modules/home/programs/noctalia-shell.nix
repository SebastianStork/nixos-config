{
  config,
  osConfig,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  options.custom.programs.noctalia-shell.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.noctalia-shell.enable {
    programs.noctalia-shell = {
      enable = true;
      systemd.enable = true;
      settings = {
        general = {
          animationSpeed = 1.8;
          enableShadows = false;
          compactLockScreen = true;
          autoStartAuth = true;
          allowPasswordWithFprintd = true;
          showSessionButtonsOnLockScreen = false;
          avatarImage = "/home/seb/Pictures/face";
          telemetryEnabled = false;
        };
        ui.boxBorderEnabled = true;
        colorSchemes = {
          darkMode =
            {
              dark = true;
              light = false;
            }
            .${config.custom.theme};
          predefinedScheme = "GitHub Dark";
        };
        wallpaper = {
          enabled = true;
          directory = "/home/seb/Pictures/Wallpapers";
          transitionType = "fade";
          transitionDuration = 1000;
          automationEnabled = true;
          randomIntervalSec = 1800;
        };
        bar = {
          barType = "simple";
          position = "bottom";
          density = "default";
          fontScale = 1.2;
          widgetSpacing = 10;
          widgets = {
            left = lib.singleton {
              id = "Clock";
              formatHorizontal = "HH:mm ddd, d MMM";
              tooltipFormat = "yyyy-MM-dd HH:mm";
            };
            center = lib.singleton {
              id = "Workspace";
            };
            right = [
              { id = "Tray"; }
              {
                id = "NotificationHistory";
                hideWhenZeroUnread = true;
              }
              { id = "Volume"; }
              (lib.optionalAttrs osConfig.custom.networking.underlay.wireless.enable { id = "Network"; })
              (lib.optionalAttrs osConfig.custom.services.bluetooth.enable { id = "Bluetooth"; })
              (lib.optionalAttrs config.custom.programs.brightnessctl.enable { id = "Brightness"; })
              {
                id = "Battery";
                displayMode = "icon-hover";
              }
            ];
          };
        };
        dock.enabled = false;
        appLauncher = {
          overviewLayer = true;
          showCategories = false;
          enableSessionSearch = false;
          enableSettingsSearch = false;
          enableWindowsSearch = false;
          enableClipboardHistory = true;
        };
        location.name = "Darmstadt";
        sessionMenu = {
          largeButtonsStyle = false;
          countdownDuration = 3000;
        };
        audio.mprisBlacklist = "firefox";
      };
    };
  };
}
