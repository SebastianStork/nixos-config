{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.de.wluma.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.wluma.enable {
    home.packages = [ pkgs.wluma ];

    xdg.configFile."wluma/config.toml".source = (pkgs.formats.toml { }).generate "wluma-config" {
      als.iio = {
        path = "/sys/bus/iio/devices";
        thresholds = {
          "0" = "night";
          "5" = "dark";
          "10" = "dim";
          "80" = "normal";
          "900" = "bright";
          "3000" = "outdoors";
        };
      };
      output.backlight = [
        {
          name = "eDP-1";
          path = "/sys/class/backlight/amdgpu_bl1";
          capturer = "wayland";
        }
      ];
    };

    systemd.user.services.wluma = {
      Install.WantedBy = [ "graphical-session.target" ];
      Unit = {
        Description = "Automatic brightness adjustment based on screen contents and ALS";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        X-Restart-Triggers = [ config.xdg.configFile."wluma/config.toml".source ];
      };
      Service = {
        ExecStart = lib.getExe pkgs.wluma;
        Restart = "always";
      };
    };
  };
}
