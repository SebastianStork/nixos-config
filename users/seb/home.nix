{pkgs, ...}: {
  myConfig = {
    qtile.enable = true;
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

  services.clipmenu = {
    enable = true;
    launcher = "rofi";
  };

  home.packages = with pkgs; [
    # CLI
    fastfetch
    btop

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
    libreoffice
    hunspell
    hunspellDicts.de_DE
    hunspellDicts.en_US
    steam
    networkmanagerapplet

    # Fonts
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
    corefonts
    roboto
    open-sans
    ubuntu_font_family
  ];
}
