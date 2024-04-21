{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.de;
in {
    options.myConfig.de.tray.syncthing.enable = lib.mkEnableOption "";

    config = lib.mkIf cfg.tray.syncthing.enable {
        home.packages = [pkgs.syncthingtray-minimal];

        systemd.user.services = {
            syncthingtray = {
                Unit = {
                    Description = "Syncthingtray";
                    Requires = ["tray.target"];
                    After = [
                        "graphical-session-pre.target"
                        "tray.target"
                    ];
                    PartOf = ["graphical-session.target"];
                };
                Service.ExecStart = "${lib.getExe' pkgs.syncthingtray-minimal "syncthingtray"} --wait";
                Install.WantedBy = ["graphical-session.target"];
            };
        };
    };
}
