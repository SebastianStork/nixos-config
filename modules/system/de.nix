{
    inputs,
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.de;
in {
    options.myConfig.de = {
        qtile.enable = lib.mkEnableOption "";
        hyprland.enable = lib.mkEnableOption "";
    };

    config = lib.mkMerge [
        (lib.mkIf cfg.qtile.enable {
            services.xserver = {
                enable = true;

                windowManager.qtile.enable = true;
                desktopManager.wallpaper.mode = "fill";

                xkb = {
                    layout = "de";
                    variant = "nodeadkeys";
                };

                libinput = {
                    enable = true;

                    touchpad = {
                        accelProfile = "adaptive";
                        naturalScrolling = true;
                        disableWhileTyping = true;
                    };

                    mouse = {
                        accelProfile = "flat";
                        middleEmulation = false;
                    };
                };
            };

            xdg.portal = {
                enable = true;
                extraPortals = [pkgs.xdg-desktop-portal-gtk];
            };

            services.gvfs.enable = true;
        })

        (lib.mkIf cfg.hyprland.enable {
            programs.hyprland = {
                enable = true;
                package = inputs.hyprland.packages.${pkgs.system}.hyprland;
            };

            environment.sessionVariables = {
                WLR_NO_HARDWARE_CURSORS = "1";
                NIXOS_OZONE_WL = "1";
            };

            xdg.portal = {
                enable = true;
                extraPortals = [pkgs.xdg-desktop-portal-gtk];
            };

            services.gvfs.enable = true;
        })
    ];
}
