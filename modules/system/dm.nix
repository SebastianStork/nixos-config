{
    config,
    lib,
    ...
}: {
    options.myConfig.dm.lightdm.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.dm.lightdm.enable {
        services.xserver = {
            enable = true;

            displayManager.lightdm = {
                enable = true;
                greeters.slick.enable = true;
            };
        };

        myConfig.x-input.enable = true;
    };
}
