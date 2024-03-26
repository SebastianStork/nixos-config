{pkgs, ...}: {
    imports = [../modules/system];

    system.stateVersion = "23.11";

    nix.settings = {
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
        warn-dirty = false;
        trusted-users = ["root" "@wheel"];
    };

    console.keyMap = "de-latin1-nodeadkeys";
    time.timeZone = "Europe/Berlin";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
        LC_ADDRESS = "de_DE.UTF-8";
        LC_IDENTIFICATION = "de_DE.UTF-8";
        LC_MEASUREMENT = "de_DE.UTF-8";
        LC_MONETARY = "de_DE.UTF-8";
        LC_NAME = "de_DE.UTF-8";
        LC_NUMERIC = "de_DE.UTF-8";
        LC_PAPER = "de_DE.UTF-8";
        LC_TELEPHONE = "de_DE.UTF-8";
        LC_TIME = "de_DE.UTF-8";
    };

    environment.systemPackages = [
        pkgs.git
        pkgs.neovim
    ];

    nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (pkgs.lib.getName pkg) [
            "spotify"
            "discord"
            "steam"
            "steam-original"
            "steam-run"
            "corefonts"
            "nvidia-x11"
            "nvidia-settings"
        ];
}
