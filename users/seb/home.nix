{
    config,
    pkgs,
    osConfig,
    myWrappers,
    ...
}: {
    xdg.userDirs.extraConfig.XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";

    myConfig = {
        de = {
            hyprland.enable = osConfig.myConfig.de.hyprland.enable;
            wallpaper = ./wallpaper;
        };

        shell = {
            bash.enable = true;
            starship.enable = true;
            enhancement.enable = true;
        };

        ssh-client.enable = true;
        git.enable = true;
        vscode.enable = true;
        equalizer.enable = true;
        sops.enable = false;
    };

    home.packages = [
        pkgs.fastfetch

        pkgs.notepadqq
        pkgs.brave
        pkgs.cinnamon.nemo-with-extensions
        pkgs.jetbrains.idea-community
        pkgs.vlc
        pkgs.onlyoffice-bin_latest
        pkgs.libreoffice
        pkgs.hunspell
        pkgs.hunspellDicts.de_DE
        pkgs.hunspellDicts.en_US

        myWrappers.bottom
        myWrappers.spotify
        myWrappers.obsidian
        myWrappers.marktext
        myWrappers.webcord
        (myWrappers.kitty {inherit (config.myConfig.de) theme;})
    ];
}
