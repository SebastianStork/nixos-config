{ config, lib, ... }:
{
  options.myConfig.de.waybar.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.waybar.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;

      settings.mainBar = {
        output = [
          "DP-1"
          "eDP-1"
        ];
        layer = "top";
        position = "bottom";
        spacing = 10;

        modules-left = [ "clock" ];
        modules-center = [ "hyprland/workspaces" ];
        modules-right = [
          "tray"
          "network"
          "wireplumber"
          "backlight"
          "battery"
        ];

        clock = {
          format = " {:%H:%M}";
          tooltip-format = "{:%d.%m.%Y}";
        };

        "hyprland/workspaces" = {
          active-only = false;
          all-outputs = true;
        };

        tray = {
          icon-size = 20;
          spacing = 6;
        };

        network = {
          interval = 10;
          format = "";
          format-disconnected = "󰪎";
          format-ethernet = "󰌗";
          format-icons = [
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          format-wifi = "{icon}";
          tooltip-format-disconnected = "Disconnected";
          tooltip-format-ethernet = "󰇚 {bandwidthDownBits} 󰕒 {bandwidthUpBits}";
          tooltip-format-wifi = "{essid}  󰇚 {bandwidthDownBits} 󰕒 {bandwidthUpBits}";
        };

        wireplumber = {
          format = "{icon} {volume}%";
          format-icons = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          format-muted = "󰝟";
          scroll-step = "5";
        };

        backlight = {
          device = "amdgpu_bl1";
          format = "{icon} {percent}%";
          format-icons = [
            "󰃞"
            "󰃟"
            "󰃠"
          ];
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          states = {
            critical = 5;
            warning = 15;
          };
        };
      };

      style = ''
        * {
          border: none;
          border-radius: 0px;
          font-family: "Open Sans, Symbols Nerd Font Mono";
          font-size: 15px;
        }
      '';
    };
  };
}
