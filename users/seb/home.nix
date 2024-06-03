{
  config,
  pkgs,
  osConfig,
  wrappers,
  ...
}:
{
  myConfig = {
    de.hyprland.enable = osConfig.myConfig.de.hyprland.enable;
    shell.enable = true;
    ssh-client.enable = true;
    git.enable = true;
    vscode.enable = true;
    equalizer.enable = true;
    sops.enable = false;
  };

  home.packages = [
    pkgs.fastfetch

    pkgs.cinnamon.nemo-with-extensions
    pkgs.jetbrains.idea-community
    pkgs.vlc
    pkgs.gnome.gnome-calculator
    pkgs.onlyoffice-bin_latest
    pkgs.libreoffice
    pkgs.hunspell
    pkgs.hunspellDicts.de_DE
    pkgs.hunspellDicts.en_US
    pkgs.webcord
    pkgs.spotify
    pkgs.obsidian
    pkgs.marktext

    wrappers.bottom
    (wrappers.kitty { inherit (config.myConfig) theme; })
    wrappers.firefox
  ];
}
