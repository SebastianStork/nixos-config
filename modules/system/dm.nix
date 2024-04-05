{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.dm;
in {
    options.myConfig.dm = {
        gdm.enable = lib.mkEnableOption "";
    };

    config = {
        services.xserver.displayManager.gdm.enable = cfg.gdm.enable;
    };
}
