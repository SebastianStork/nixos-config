{
  config,
  pkgs,
  wrappers,
  ...
}:
{
  imports = [ ../common-home.nix ];

  myConfig = {
    sops.enable = true;
    shell.zsh.enable = true;
    git.enable = true;
    vscode.enable = true;
    equalizer.enable = true;
    night-light.enable = true;
  };

  home.packages = [
    pkgs.fastfetch
    pkgs.just

    (wrappers.kitty { inherit (config.myConfig) theme; })
    wrappers.firefox
    pkgs.cinnamon.nemo-with-extensions
    pkgs.jetbrains.idea-community
    pkgs.celluloid
    pkgs.spotify
    pkgs.obsidian
    pkgs.webcord
    pkgs.onlyoffice-bin_latest
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
