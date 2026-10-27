{
  config,
  self,
  pkgs,
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

    services = {
      ntfy-client.enable = true;
      syncthing.folders = [
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Projects"
        "Vault"
        "Videos"
      ];
    };

    programs = {
      shell = {
        zsh.enable = true;
        aliases.enable = true;
        direnv.enable = true;
        atuin-client.enable = true;
      };
      ssh.enable = true;
      git.enable = true;
      firefox.enable = true;
      vscode.enable = true;
      discord.enable = true;
      spotify.enable = true;
      libreoffice.enable = true;
      nemo.enable = true;
      obsidian.enable = true;
      herdr.enable = true;
      btop.enable = true;
      pi-coding-agent.enable = true;
    };
  };

  home.packages = [
    pkgs.fastfetch

    pkgs.vlc
    pkgs.anki
    pkgs.calibre

    pkgs.corefonts
  ];
}
