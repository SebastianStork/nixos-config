{
    config,
    pkgs,
    lib,
    osConfig,
    ...
}: {
    options.myConfig.de.qtile.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.de.qtile.enable {
        assertions = [
            {
                assertion = osConfig.services.xserver.windowManager.qtile.enable;
                message = "Qtile has to be enabled on the system level";
            }
        ];

        home.file.".config/qtile/config.py".source = ./config.py;
        home.file.".background-image".source = config.myConfig.de.wallpaper;

        home.packages = [
            # Widget dependencies
            pkgs.python311Packages.iwlib
            pkgs.python311Packages.psutil
            pkgs.lm_sensors

            # Hotkey dependencies
            pkgs.playerctl
            pkgs.brightnessctl
        ];

        myConfig.rofi = {
            enable = true;
            clipboard.enable = true;
        };

        services.picom = {
            enable = true;
            vSync = true;
        };

        services.dunst.enable = true;
    };
}
