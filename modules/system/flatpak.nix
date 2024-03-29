{
    config,
    lib,
    ...
}: {
    options.myConfig.flatpak.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.flatpak.enable {
        services.flatpak.enable = true;

        home-manager.sharedModules = [
            {
                xdg = {
                    enable = true;
                    systemDirs.data = [
                        "/var/lib/flatpak/exports/share"
                        "/home/seb/.local/share/flatpak/exports/share"
                    ];
                };
            }
        ];
    };
}
