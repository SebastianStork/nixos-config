{
    pkgs,
    osConfig,
    ...
}: {
    myConfig = {
        de = {
            qtile.enable = true;
            wallpaper = ./wallpaper;
            theming.enable = true;
            tray = {
                syncthing.enable = osConfig.myConfig.syncthing.enable;
                networkmanager.enable = osConfig.networking.networkmanager.enable;
            };
        };
        shell = {
            bash.enable = true;
            starship.enable = true;
            nixAliases.enable = true;
            improvedCommands.enable = true;
            direnv.enable = true;
        };
        ssh-client.enable = true;
        git.enable = true;
        neovim.enable = true;
        vscode.enable = true;
        kitty.enable = true;
    };

    programs.btop.enable = true;

    home.packages = with pkgs; [
        notepadqq
        brave
        spotify
        cinnamon.nemo-with-extensions
        discord
        flameshot
        jetbrains.idea-community
        vlc
        obs-studio
        libsForQt5.kdenlive
        gimp
        onlyoffice-bin_latest
    ];
}
