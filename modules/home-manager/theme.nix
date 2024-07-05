{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig;
in
{
  options.myConfig.theme = lib.mkOption { type = lib.types.str; };

  config = lib.mkMerge [
    (lib.mkIf ((cfg.theme == "dark") || (cfg.theme == "light")) {
      gtk = {
        enable = true;
        gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        theme.package = pkgs.gnome-themes-extra;
        iconTheme.package = pkgs.papirus-icon-theme;
        font.name = "Open Sans";
        font.package = pkgs.open-sans;
      };
      qt = {
        enable = true;
        style.package = pkgs.adwaita-qt;
        platformTheme.name = "adwaita";
      };
      home.pointerCursor = {
        gtk.enable = true;
        package = pkgs.bibata-cursors;
        size = 24;
      };
    })

    (lib.mkIf (cfg.theme == "dark") {
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      gtk.theme.name = "Adwaita-dark";
      gtk.iconTheme.name = "Papirus-Dark";
      qt.style.name = "adwaita-dark";
      home.pointerCursor.name = "Bibata-Original-Classic";
    })

    (lib.mkIf (cfg.theme == "light") {
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-light";
      gtk.theme.name = "Adwaita";
      gtk.iconTheme.name = "Papirus";
      qt.style.name = "adwaita";
      home.pointerCursor.name = "Bibata-Original-Ice";
    })
  ];
}
