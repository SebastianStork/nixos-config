{
    config,
    pkgs,
    osConfig,
    ...
}: {
    myConfig = {
        de = {
            hyprland.enable = osConfig.myConfig.de.hyprland.enable;

            wallpaper = ./wallpaper;
            theming.enable = true;

            tray.syncthing.enable = osConfig.myConfig.syncthing.enable;
        };

        shell = {
            bash.enable = true;
            starship.enable = true;
            nixAliases = {
                enable = true;
                nh.enable = osConfig.programs.nh.enable;
            };
            enhancement.enable = true;
            direnv.enable = true;
        };

        ssh-client.enable = true;
        git.enable = true;

        neovim.enable = true;
        vscode.enable = true;

        kitty.enable = true;
    };

    programs.btop.enable = true;

    xdg.userDirs.extraConfig.XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";

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

        (pkgs.nerdfonts.override {
            fonts = [
                "JetBrainsMono"
                "NerdFontsSymbolsOnly"
            ];
        })
        pkgs.corefonts
        pkgs.roboto
        pkgs.open-sans
    ];

    fonts.fontconfig.enable = true;
}
