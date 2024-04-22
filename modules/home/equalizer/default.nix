{
    config,
    lib,
    ...
}: {
    options.myConfig.equalizer.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.equalizer.enable {
        services.easyeffects.enable = true;

        xdg.configFile."easyeffects/output" = {
            source = ./output;
            recursive = true;
        };
    };
}
