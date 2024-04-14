{
    config,
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
                    spacing = 3;

                    modules-left = ["clock"];
                    modules-center = ["hyprland/workspaces"];
                    modules-right = ["tray" "wireplumber" "backlight" "battery"];

                    "hyprland/workspaces" = {
                        active-only = false;
                        all-outputs = true;
                    };

                    backlight = {
                        device = "amdgpu_bl1";
                    };
                };
            };

            style = ''
                * {
                    border: none;
                    border-radius: 0px;
                    font-family: "JetBrainsMono Nerd Font";
                    font-size: 14px;
                }

                window#waybar {
                    background-color: rgba(43, 48, 59, 0.5);
                    color: #ffffff;
                }
            '';
        };
    };
}
