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
