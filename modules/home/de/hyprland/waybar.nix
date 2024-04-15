{
    config,
    pkgs,
    lib,
    ...
}: {
    config = lib.mkIf config.myConfig.de.hyprland.enable {
        programs.waybar = {
            enable = true;
            systemd.enable = true;

            settings = {
                mainBar = {
                    layer = "top";
                    position = "top";
                    spacing = 10;

                    modules-left = ["clock"];
                    modules-center = ["hyprland/workspaces"];
                    modules-right = ["tray" "wireplumber" "backlight" "battery"];

                    "hyprland/workspaces" = {
                        active-only = false;
                        all-outputs = true;
                    };

                    clock = {
                        format = " {:%H.%M}";
                        tooltip-format = "{:%d.%m.%Y}";
                    };

                    wireplumber = {
                        format = "{icon} {volume}%";
                        format-muted = "󰝟";
                        format-icons = ["󰕿" "󰖀" "󰕾"];
                        scroll-step = "5";
                    };

                    tray = {
                        icon-size = 20;
                        spacing = 6;
                    };

                    backlight = {
                        device = "amdgpu_bl1";
                        format = "{icon} {percent}%";
                        format-icons = ["󰃞" "󰃟" "󰃠"];
                    };

                    battery = {
                        states = {
                            warning = 15;
                            critical = 5;
                        };
                        format = "{icon} {capacity}%";
                        format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
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

                window#waybar {
                    background-color: rgba(43, 48, 59, 0.5);
                    color: #ffffff;
                }
            '';
        };

        xdg.configFile."waybar/config".onChange = lib.mkForce "${lib.getExe' pkgs.systemd "systemctl"} restart --user waybar";
        xdg.configFile."waybar/style.css".onChange = lib.mkForce "${lib.getExe' pkgs.systemd "systemctl"} restart --user waybar";
    };
}
