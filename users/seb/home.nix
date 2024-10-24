{
  config,
  pkgs,
  wrappers,
  ...
}:
{
  imports = [ ../common-home.nix ];

  home.sessionVariables.FLAKE = "~/Projects/nixos-config";

  myConfig = {
    sops.enable = true;
    shell.zsh.enable = true;
    git.enable = true;
    vscode.enable = true;
    equalizer.enable = true;
    nextcloud-sync.enable = true;
  };

  home.packages = [
    wrappers.bottom
    pkgs.fastfetch

    (wrappers.kitty { inherit (config.myConfig.de) theme; })
    wrappers.firefox
    pkgs.jetbrains.idea-community
    pkgs.nemo-with-extensions
    pkgs.celluloid
    pkgs.spotify

    pkgs.marktext
    pkgs.obsidian
    pkgs.todoist-electron
    pkgs.anki

    pkgs.webcord
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
