{ assembleWrapper, pkgs, ... }:
assembleWrapper {
  basePackage = pkgs.waybar;

  flags =
    let
      waybar-config = (pkgs.formats.json { }).generate "waybar-config" {
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

        "hyprland/workspaces" = {
          active-only = false;
          all-outputs = true;
        };

        clock = {
          format = " {:%H.%M}";
          tooltip-format = "{:%d.%m.%Y}";
        };

        network = {
          interval = 10;
          format = "";

          format-wifi = "{icon}";
          format-icons = [
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          tooltip-format-wifi = "{essid}  󰇚 {bandwidthDownBits} 󰕒 {bandwidthUpBits}";

          format-ethernet = "󰌗";
          tooltip-format-ethernet = "󰇚 {bandwidthDownBits} 󰕒 {bandwidthUpBits}";

          format-disconnected = "󰪎";
          tooltip-format-disconnected = "Disconnected";
        };

        wireplumber = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";
          format-icons = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          scroll-step = "5";
        };

        tray = {
          icon-size = 20;
          spacing = 6;
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
          states = {
            warning = 15;
            critical = 5;
          };
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
        };
      };
      waybar-style = pkgs.writeText "waybar-style" ''
        * {
            border: none;
            border-radius: 0px;
            font-family: "Open Sans, Symbols Nerd Font Mono";
            font-size: 15px;
        }
      '';
    in
    [
      "--config"
      waybar-config
      "--style"
      waybar-style
    ];
}
