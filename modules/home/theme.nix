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
      home.packages =
        let
          atkinsonHyperlegibleNextTtf = pkgs.atkinson-hyperlegible-next.overrideAttrs (oldAttrs: {
            postInstall = (oldAttrs.postInstall or "") + ''
              rm -rf "$out/share/fonts/opentype"
            '';
          });
        in
        [
          atkinsonHyperlegibleNextTtf
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
        font = {
          name = "sans-serif";
          size = 12;
        };
      };
      qt = {
        enable = true;
        style.package = pkgs.adwaita-qt;
        platformTheme.name = "adwaita";
      };
      home.pointerCursor = {
        gtk.enable = true;
        name = "Future-cursors";
        size = 32;
        package = pkgs.stdenvNoCC.mkDerivation {
          name = "future-cursors-cyan";
          src = pkgs.fetchFromGitHub {
            owner = "yeyushengfan258";
            repo = "Future-cursors";
            rev = "587c14d2f5bd2dc34095a4efbb1a729eb72a1d36";
            hash = "sha256-ziEgMasNVhfzqeURjYJK1l5BeIHk8GK6C4ONHQR7FyY=";
          };
          nativeBuildInputs = [
            pkgs.librsvg
            pkgs.xcursorgen
          ];
          postPatch = ''
            substituteInPlace build.sh \
              --replace-fail "create svg" "create svg-cyan" \
              --replace-fail inkscape rsvg-convert
          '';
          buildPhase = "bash build.sh";
          installPhase = ''
            mkdir -p "$out/share/icons/Future-cursors"
            cp -r dist/. "$out/share/icons/Future-cursors"
          '';
        };
      };
    }

    (lib.mkIf (theme == "dark") {
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      gtk = {
        theme.name = "Adwaita-dark";
        iconTheme.name = "Papirus-Dark";
      };
      qt.style.name = "adwaita-dark";
    })

    (lib.mkIf (theme == "light") {
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-light";
      gtk = {
        theme.name = "Adwaita";
        iconTheme.name = "Papirus";
      };
      qt.style.name = "adwaita";
    })
  ];
}
