{
    config,
    pkgs,
    lib,
    ...
}: {
    options.myConfig.de.qtile.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.de.qtile.enable {
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
            config.common.default = "*";
        };
    };
}
