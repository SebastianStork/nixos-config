{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.de;
in {
    imports = [
        ./qtile.nix
        ./hyprland.nix
    ];

    options.myConfig.de = {
        theming.enable = lib.mkEnableOption "";

        wallpaper = lib.mkOption {
            type = lib.types.path;
        };

        widget = {
            backlight = {
                enable = lib.mkEnableOption "";
                device = lib.mkOption {
                    type = lib.types.str;
                };
            };
            battery.enable = lib.mkEnableOption "";
        };

        tray = {
            syncthing.enable = lib.mkEnableOption "";
            networkmanager.enable = lib.mkEnableOption "";
        };
    };

    config = lib.mkMerge [
        (lib.mkIf cfg.theming.enable {
            dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

            gtk = {
                enable = true;

                gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

                theme.name = "Adwaita-dark";
                theme.package = pkgs.gnome.gnome-themes-extra;

                iconTheme.name = "Adwaita";
                iconTheme.package = pkgs.gnome.adwaita-icon-theme;

                font.name = "Open Sans";
                font.package = pkgs.open-sans;
            };

            qt = {
                enable = true;
                platformTheme = "gnome";
                style.name = "adwaita-dark";
                style.package = pkgs.adwaita-qt;
            };

            home.pointerCursor = {
                name = "Bibata-Original-Classic";
                package = pkgs.bibata-cursors;
                size = 24;
                x11.enable = true;
                x11.defaultCursor = "X_cursor";
                gtk.enable = true;
            };
        })

        (lib.mkIf cfg.tray.syncthing.enable {
            home.packages = [pkgs.syncthingtray-minimal];

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
            home.packages = [pkgs.networkmanagerapplet];

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
