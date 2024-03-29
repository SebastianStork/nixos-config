{pkgs, ...}: {
    myConfig = {
        de = {
            qtile.enable = true;
            wallpaper = ./wallpaper;
            tray.syncthing.enable = true;
        };
        vscode.enable = true;
        shell = {
            bash.enable = true;
            starship.enable = true;
            nixAliases.enable = true;
            improvedCommands.enable = true;
            direnv.enable = true;
        };
        theming.enable = true;
        ssh-client.enable = true;
        git.enable = true;
        neovim.enable = true;
        kitty.enable = true;
    };

    programs.btop.enable = true;

    home.packages = with pkgs; [
        # CLI
        fastfetch

        # GUI
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
        libreoffice
        hunspell
        hunspellDicts.de_DE
        hunspellDicts.en_US

        # Fonts
        (nerdfonts.override {fonts = ["JetBrainsMono" "NerdFontsSymbolsOnly"];})
        corefonts
        roboto
        open-sans
    ];
}
