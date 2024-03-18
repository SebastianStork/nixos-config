{
    config,
    lib,
    ...
}: {
    options.myConfig.auto-gc.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.auto-gc.enable {
        myConfig.nix-helper.enable = true;

        nh.clean = {
            enable = true;
            dates = "weekly";
            extraArgs = "--keep-since 7d --keep 10";
        };
    };
}
