{
    inputs,
    config,
    lib,
    ...
}: {
    imports = [inputs.hyprlock.homeManagerModules.hyprlock];

    options.myConfig.de.hypridlelock.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.de.hypridlelock.enable {
        programs.hyprlock = {
            enable = true;

            backgrounds = [
                {
                    path = "screenshot";
                    blur_passes = 1;
                    blur_size = 4;
                }
            ];
        };

        services.hypridle = {
            enable = true;

            settings = {
                general = {
                    lock_cmd = let
                        hyprlockExe = "${lib.getExe config.programs.hyprlock.package}";
                    in "pidof ${hyprlockExe} || ${hyprlockExe}";
                    before_sleep_cmd = "loginctl lock-session";
                    after_sleep_cmd = "hyprctl dispatch dpms on";
                };

                listener = [
                    {
                        timeout = 600;
                        on-timeout = "loginctl lock-session";
                    }
                ];
            };
        };
    };
}
