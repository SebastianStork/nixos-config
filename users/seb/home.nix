{
    config,
    pkgs,
    osConfig,
    wrappers,
    ...
}: {
    xdg.userDirs.extraConfig.XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";

    myConfig = {
        de.hyprland.enable = osConfig.myConfig.de.hyprland.enable;

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
        clipboard.enable = true;
    };

    home.packages = [
        pkgs.fastfetch

        pkgs.brave
        pkgs.cinnamon.nemo-with-extensions
        pkgs.jetbrains.idea-community
        pkgs.vlc
        pkgs.onlyoffice-bin_latest
        pkgs.libreoffice
        pkgs.hunspell
        pkgs.hunspellDicts.de_DE
        pkgs.hunspellDicts.en_US

        wrappers.bottom
        wrappers.spotify
        wrappers.obsidian
        wrappers.marktext
        wrappers.webcord
        (wrappers.kitty {inherit (config.myConfig.de) theme;})
        (wrappers.rofi {inherit (config.myConfig.de) theme;})
    ];
}
