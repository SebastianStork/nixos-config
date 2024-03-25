{
    config,
    pkgs,
    lib,
    osConfig,
    ...
}: let
    cfg = config.myConfig.dm;
in {
    imports = [./qtile];

    options.myConfig.dm.tray = {
        syncthing.enable = lib.mkEnableOption "";
        networkmanager.enable = lib.mkEnableOption "";
    };

    config = lib.mkMerge [
        (lib.mkIf cfg.tray.syncthing.enable {
            assertions = [
                {
                    assertion = osConfig.services.syncthing.enable;
                    message = "Syncthing has to be enabled on the system level.";
                }
            ];

            xsession.enable = osConfig.services.xserver.enable;

            systemd.user.services = {
                syncthingtray = lib.mkIf cfg.tray.syncthing.enable {
                    Unit = {
                        Description = "Syncthingtray";
                        Requires = ["tray.target"];
                        After = ["graphical-session-pre.target" "tray.target"];
                        PartOf = ["graphical-session.target"];
                    };
                    Service = {
                        ExecStart = "${pkgs.syncthingtray-minimal}/bin/syncthingtray --wait";
                    };
                    Install = {
                        WantedBy = ["graphical-session.target"];
                    };
                };
            };
        })

        (lib.mkIf cfg.tray.networkmanager.enable {
            assertions = [
                {
                    assertion = osConfig.networking.networkmanager.enable;
                    message = "Networkmanager has to be enabled on the system level.";
                }
            ];

            xsession.enable = osConfig.services.xserver.enable;

            systemd.user.services = {
                nm-applet = lib.mkIf cfg.tray.networkmanager.enable {
                    Unit = {
                        Description = "Networkmanager-applet";
                        Requires = ["tray.target"];
                        After = ["graphical-session-pre.target" "tray.target"];
                        PartOf = ["graphical-session.target"];
                    };
                    Service = {
                        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
                    };
                    Install = {
                        WantedBy = ["graphical-session.target"];
                    };
                };
            };
        })
    ];
}
