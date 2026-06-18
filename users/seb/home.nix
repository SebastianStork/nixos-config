{
  config,
  self,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  imports = [ self.homeModules.default ];

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
      extraConfig.SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
    };
  };

  custom = {
    sops.enable = true;

    desktop.hyprland.noctalia.enable = true;

    services.ntfy-client.enable = true;

    programs = {
      shell = {
        zsh.enable = true;
        aliases.enable = true;
        direnv.enable = true;
        atuin-client.enable = true;
      };
      ssh.enable = true;
      git.enable = true;
      kitty.enable = true;
      vscode.enable = true;
      firefox.enable = true;
      libreoffice.enable = true;
      btop.enable = true;
    };
  };

  home.packages = [
    pkgs.fastfetch
    pkgs-unstable.claude-code

    pkgs.nemo-with-extensions
    pkgs.vlc
    pkgs.spotify
    pkgs.obsidian
    pkgs.anki
    pkgs.discord
    pkgs.zed-editor

    pkgs.corefonts
    pkgs.roboto
    pkgs.open-sans
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.symbols-only
  ];

  fonts.fontconfig.enable = true;
}
