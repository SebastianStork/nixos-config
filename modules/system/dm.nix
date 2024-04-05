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
        tuigreet.enable = lib.mkEnableOption "";
    };

    config = {
        services.xserver.displayManager.gdm.enable = cfg.gdm.enable;

        services.greetd = lib.mkIf cfg.tuigreet.enable {
            enable = true;
            settings = {
                terminal.vt = "next";
                default_session = let
                    base = config.services.xserver.displayManager.sessionData.desktops;
                in {
                    command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --asterisks --remember --remember-user-session --sessions ${base}/share/wayland-sessions:${base}/share/xsessions";
                    user = "greeter";
                };
            };
        };
    };
}
