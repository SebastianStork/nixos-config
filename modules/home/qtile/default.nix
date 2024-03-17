{
    config,
    pkgs,
    lib,
    osConfig,
    ...
}: {
    options.myConfig.qtile.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.qtile.enable {
        assertions = [
            {
                assertion = osConfig.services.xserver.windowManager.qtile.enable;
                message = "Qtile has to be enabled on the system level";
            }
        ];

        home.file.".config/qtile/config.py".source = ./files/qtile.py;
        home.file.".background-image".source = ./files/background-image;

        home.packages = [
            # Widget dependencies
            pkgs.python311Packages.iwlib
            pkgs.python311Packages.psutil
            pkgs.lm_sensors

            # Hotkey dependencies
            pkgs.playerctl
            pkgs.brightnessctl
        ];

        programs.rofi = {
            enable = true;
            theme = ./files/rofi-theme.rasi;
        };

        services.picom = {
            enable = true;
            vSync = true;
        };

        services.dunst.enable = true;
    };
}
