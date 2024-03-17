{
    config,
    pkgs,
    lib,
    ...
}: {
    options.myConfig.theming.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.theming.enable {
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

        fonts.fontconfig.enable = true;
    };
}
