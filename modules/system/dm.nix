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
        services.xserver = lib.mkIf cfg.gdm.enable {
            enable = true;
            displayManager.gdm.enable = true;
        };

        services.greetd = lib.mkIf cfg.tuigreet.enable {
            enable = true;
            settings = {
                default_session = let
                    base = config.services.xserver.displayManager.sessionData.desktops;
                in {
                    command = "${lib.getExe pkgs.greetd.tuigreet} --time --asterisks --remember --remember-user-session --sessions ${base}/share/wayland-sessions:${base}/share/xsessions";
                    user = "greeter";
                };
            };
        };
    };
}
