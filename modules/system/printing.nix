{
    config,
    lib,
    ...
}: {
    options.myConfig.printing.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.printing.enable {
        services.printing.enable = true;
        services.avahi = {
            enable = true;
            nssmdns = true;
            openFirewall = true;
        };
    };
}
