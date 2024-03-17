{
    config,
    lib,
    ...
}: {
    options.myConfig.de.qtile.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.de.qtile.enable {
        services.xserver = {
            enable = true;

            windowManager.qtile.enable = true;
            desktopManager.wallpaper.mode = "fill";
        };

        myConfig.x-input.enable = true;
    };
}
