{
  config,
  pkgs,
  wrappers,
  ...
}:
{
  imports = [ ../common-home.nix ];

  home.sessionVariables.FLAKE = "~/Projects/nixos/my-config";

  myConfig = {
    sops.enable = true;
    shell.zsh.enable = true;
    git.enable = true;
    vscode.enable = true;
    equalizer.enable = true;
    nextcloud.enable = true;
  };

  home.packages = [
    wrappers.bottom
    pkgs.fastfetch

    (wrappers.kitty { inherit (config.myConfig.de) theme; })
    wrappers.firefox
    pkgs.nemo-with-extensions
    pkgs.jetbrains.idea-community
    pkgs.spotify
    pkgs.obsidian
    pkgs.ticktick
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
