{
  config,
  self,
  pkgs,
  ...
}:
{
  imports = [ self.homeManagerModules.default ];

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      extraConfig.XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
    };
  };

  home.sessionVariables.NH_FLAKE = "~/Projects/nixos-config";

  custom = {
    sops.enable = true;

    programs = {
      shell = {
        zsh.enable = true;
        aliases.enable = true;
        direnv.enable = true;
      };
      git.enable = true;
      kitty.enable = true;
      vscode.enable = true;
      firefox.enable = true;
      libreoffice.enable = true;
    };
  };

  home.packages = [
    pkgs.bottom
    pkgs.fastfetch

    pkgs.nemo-with-extensions
    pkgs.vlc
    pkgs.spotify
    pkgs.obsidian
    pkgs.anki
    pkgs.discord

    pkgs.jetbrains.clion
    pkgs.jetbrains.pycharm-professional

    pkgs.corefonts
    pkgs.roboto
    pkgs.open-sans
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.symbols-only
  ];

  fonts.fontconfig.enable = true;
}
