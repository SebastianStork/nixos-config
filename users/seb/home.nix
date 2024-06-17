{
  config,
  pkgs,
  wrappers,
  ...
}:
{
  myConfig = {
    de.hyprland.enable = true;
    shell.zsh.enable = true;
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
    pkgs.celluloid
    pkgs.onlyoffice-bin_latest

    wrappers.bottom
    wrappers.spotify
    wrappers.obsidian
    wrappers.webcord
    (wrappers.kitty { inherit (config.myConfig) theme; })
    wrappers.firefox
  ];
}
