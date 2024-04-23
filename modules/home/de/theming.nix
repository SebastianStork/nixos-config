{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.de;
in {
    options.myConfig.de = {
        theming.enable = lib.mkEnableOption "";
        wallpaper = lib.mkOption {
            type = lib.types.path;
        };
    };

    config = lib.mkIf cfg.theming.enable {
        dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

        gtk = {
            enable = true;

            gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

            theme.name = "Adwaita-dark";
            theme.package = pkgs.gnome.gnome-themes-extra;

            iconTheme.name = "Papirus-Dark";
            iconTheme.package = pkgs.papirus-icon-theme;

            font.name = "Open Sans";
            font.package = pkgs.open-sans;
        };

        qt = {
            enable = true;
            platformTheme.name = "adwaita";
            style.name = "adwaita-dark";
            style.package = pkgs.adwaita-qt;
        };

        home.pointerCursor = {
            name = "Bibata-Original-Classic";
            package = pkgs.bibata-cursors;
            size = 24;
            gtk.enable = true;
        };
    };
}
