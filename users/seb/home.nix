{
  config,
  pkgs,
  wrappers,
  ...
}:
{
  myConfig = {
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
