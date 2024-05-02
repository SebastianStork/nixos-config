{
    config,
    pkgs,
    osConfig,
    ...
}: {
    xdg.userDirs.extraConfig.XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";

    myConfig = {
        de = {
            hyprland.enable = osConfig.myConfig.de.hyprland.enable;
            wallpaper = ./wallpaper;
            tray.syncthing.enable = osConfig.myConfig.syncthing.enable;
        };

        shell = {
            bash.enable = true;
            starship.enable = true;
            enhancement.enable = true;
        };

        ssh-client.enable = true;
        git.enable = true;
        vscode.enable = true;
        kitty.enable = true;
        equalizer.enable = true;
        sops.enable = true;
    };

    home.packages = [
        pkgs.btop
        pkgs.fastfetch

        pkgs.notepadqq
        pkgs.brave
        pkgs.spotify
        pkgs.cinnamon.nemo-with-extensions
        pkgs.webcord
        pkgs.jetbrains.idea-community
        pkgs.vlc
        pkgs.onlyoffice-bin_latest
        pkgs.libreoffice
        pkgs.hunspell
        pkgs.hunspellDicts.de_DE
        pkgs.hunspellDicts.en_US
        pkgs.marktext
        pkgs.obsidian
    ];
}
