{
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  lazyApp = pkg: inputs.lazy-apps.packages.${pkgs.system}.lazy-app.override { inherit pkg; };
  lazyDesktopApp =
    pkg:
    inputs.lazy-apps.packages.${pkgs.system}.lazy-app.override {
      inherit pkg;
      desktopItem = pkgs.makeDesktopItem {
        name = pkg.meta.mainProgram;
        exec = "${pkg.meta.mainProgram} %U";
        icon = pkg.meta.mainProgram;
        desktopName = pkg.meta.mainProgram;
        comment = pkg.meta.description;
      };
    };
in
{
  imports = [ ../shared-home.nix ];

  home.sessionVariables.FLAKE = "~/Projects/nixos-config";

  myConfig = {
    kitty.enable = true;
    firefox.enable = true;
    sops.enable = true;
    shell.zsh.enable = true;
    git.enable = true;
    vscode.enable = true;
    equalizer.enable = true;
  };

  home.packages = [
    pkgs.bottom
    (lazyApp pkgs.fastfetch)
    (lazyApp pkgs.dust)

    pkgs.nemo-with-extensions
    pkgs.celluloid
    pkgs-unstable.spotify
    pkgs.obsidian
    pkgs-unstable.anki
    pkgs-unstable.discord
    (lazyDesktopApp pkgs.brave)

    pkgs.jetbrains.idea-community
    pkgs.jetbrains.goland
    pkgs.qtcreator
    pkgs-unstable.logisim-evolution

    pkgs.libreoffice
    pkgs.hunspell
    pkgs.hunspellDicts.de_DE
    pkgs.hunspellDicts.en_US

    pkgs.corefonts
    pkgs.roboto
    pkgs.open-sans
    (pkgs.nerdfonts.override {
      fonts = [
        "JetBrainsMono"
        "NerdFontsSymbolsOnly"
      ];
    })
  ];

  fonts.fontconfig.enable = true;
}
