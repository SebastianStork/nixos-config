{ pkgs, pkgs-unstable, ... }:
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
    pkgs.fastfetch

    pkgs.nemo-with-extensions
    pkgs.celluloid
    pkgs.spotify

    pkgs.jetbrains.idea-community
    pkgs.jetbrains.goland
    pkgs.qtcreator

    pkgs.marktext
    pkgs.obsidian
    pkgs.todoist-electron
    pkgs-unstable.anki

    pkgs-unstable.discord
    pkgs.signal-desktop
    pkgs.element-desktop

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
