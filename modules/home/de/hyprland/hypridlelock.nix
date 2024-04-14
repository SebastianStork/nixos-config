{
    inputs,
    config,
    pkgs,
    lib,
    ...
}: {
    imports = [
        inputs.hyprlock.homeManagerModules.hyprlock
        inputs.hypridle.homeManagerModules.hypridle
    ];

    config = lib.mkIf config.myConfig.de.hyprland.enable {
        programs.hyprlock = {
            enable = true;
            backgrounds = [
                {
                    path = "screenshot";
                    blur_passes = 1;
                    blur_size = 6;
                }
            ];
        };

        services.hypridle = let
            hyprlockExe = "${lib.getExe inputs.hyprlock.packages.${pkgs.system}.default}";
        in {
            enable = true;
            lockCmd = "pidof ${hyprlockExe} || ${hyprlockExe}";
            # beforeSleepCmd = "loginctl lock-session";
            afterSleepCmd = "hyprctl dispatch dpms on";
            listeners = [
                {
                    timeout = 600;
                    onTimeout = "hyprctl dispatch dpms off";
                    onResume = "hyprctl dispatch dpms on";
                }
                {
                    timeout = 1200;
                    onTimeout = "loginctl lock-session";
                }
            ];
        };
    };
}