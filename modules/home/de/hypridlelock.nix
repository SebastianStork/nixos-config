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

    options.myConfig.de.hypridlelock.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.de.hypridlelock.enable {
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
                    onTimeout = "loginctl lock-session";
                }
            ];
        };
    };
}