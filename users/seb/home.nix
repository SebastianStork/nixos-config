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

    home.packages = [
        pkgs.notepadqq
        pkgs.brave
        pkgs.spotify
        pkgs.cinnamon.nemo-with-extensions
        pkgs.discord
        pkgs.flameshot
        pkgs.jetbrains.idea-community
        pkgs.vlc
        pkgs.onlyoffice-bin_latest

        (pkgs.nerdfonts.override {fonts = ["JetBrainsMono" "NerdFontsSymbolsOnly"];})
        pkgs.corefonts
        pkgs.roboto
        pkgs.open-sans
    ];

    fonts.fontconfig.enable = true;
}
