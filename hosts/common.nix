{pkgs, ...}: {
    imports = [../modules/system];

    system.stateVersion = "23.11";

    nix.settings = {
        experimental-features = [
            "nix-command"
            "flakes"
        ];
        auto-optimise-store = true;
        warn-dirty = false;
        trusted-users = [
            "root"
            "@wheel"
        ];

        substituters = ["https://hyprland.cachix.org"];
        trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

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

    console.keyMap = "de-latin1-nodeadkeys";

    programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
    };

    environment.systemPackages = [pkgs.git];

    nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (pkgs.lib.getName pkg) [
            "steam"
            "steam-original"
            "steam-run"
            "corefonts"
            "nvidia-x11"
            "nvidia-settings"
        ];

    users.mutableUsers = false;
}
