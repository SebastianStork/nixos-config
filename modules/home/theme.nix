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
      home.packages = [
        pkgs.atkinson-hyperlegible-next
        pkgs.literata
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.nerd-fonts.symbols-only
        pkgs.noto-fonts-color-emoji
      ];
      fonts.fontconfig = {
        enable = true;
        defaultFonts = {
          sansSerif = [ "Atkinson Hyperlegible Next" ];
          serif = [ "Literata" ];
          monospace = [ "JetBrainsMono Nerd Font" ];
          emoji = [ "Noto Color Emoji" ];
        };
        configFile.jetbrains-mono-hinting = {
          enable = true;
          text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>JetBrainsMono Nerd Font</string>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintfull</const>
                </edit>
              </match>
            </fontconfig>
          '';
        };
      };

      gtk = {
        enable = true;
        gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        theme.package = pkgs.gnome-themes-extra;
        gtk4.theme = config.gtk.theme;
        iconTheme.package = pkgs.papirus-icon-theme;
        font.name = "sans-serif";
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
