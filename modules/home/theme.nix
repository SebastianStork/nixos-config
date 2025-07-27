{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.custom) theme;
in
{
  options.custom.theme = lib.mkOption {
    type = lib.types.enum [
      "dark"
      "light"
    ];
  };

  config = lib.mkMerge [
    {
      gtk = {
        enable = true;
        gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        theme.package = pkgs.gnome-themes-extra;
        iconTheme.package = pkgs.papirus-icon-theme;
        font = {
          name = "Open Sans";
          package = pkgs.open-sans;
        };
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
    }

    (lib.mkIf (theme == "dark") {
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      gtk = {
        theme.name = "Adwaita-dark";
        iconTheme.name = "Papirus-Dark";
      };
      qt.style.name = "adwaita-dark";
      home.pointerCursor.name = "Bibata-Original-Classic";
    })

    (lib.mkIf (theme == "light") {
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-light";
      gtk = {
        theme.name = "Adwaita";
        iconTheme.name = "Papirus";
      };
      qt.style.name = "adwaita";
      home.pointerCursor.name = "Bibata-Original-Ice";
    })
  ];
}
