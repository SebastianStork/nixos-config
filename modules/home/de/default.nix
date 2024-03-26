{
    config,
    pkgs,
    lib,
    osConfig,
    ...
}: let
    cfg = config.myConfig.de;
in {
    imports = [./qtile];

    options.myConfig.de = {
        wallpaper = lib.mkOption {
            type = lib.types.path;
        };
        tray = {
            syncthing.enable = lib.mkEnableOption "";
            networkmanager.enable = lib.mkEnableOption "";
        };
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
                syncthingtray = {
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
                nm-applet = {
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
