{lib, ...}: {
    imports = [
        ./qtile.nix
        ./hyprland

        ./theming.nix
        ./rofi
        ./tray.nix
        ./waybar.nix
        ./hypridlelock.nix
    ];

    options.myConfig.de = {
        widget = {
            backlight = {
                enable = lib.mkEnableOption "";
                device = lib.mkOption {
                    type = lib.types.str;
                };
            };
            battery.enable = lib.mkEnableOption "";
        };
    };
}
