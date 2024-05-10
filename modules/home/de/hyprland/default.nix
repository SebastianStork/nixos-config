{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.de;
in {
    imports = [
        ./config.nix
        ./keybinds.nix
    ];

    options.myConfig.de.hyprland.enable = lib.mkEnableOption "";

    config = lib.mkIf cfg.hyprland.enable {
        home.packages = [pkgs.hyprpaper];
        xdg.configFile."hypr/hyprpaper.conf".text = ''
            preload=${cfg.wallpaper}
            wallpaper=,${cfg.wallpaper}
            splash=false
        '';

        services.dunst.enable = true;

        myConfig.de = {
            hypridlelock.enable = true;
            waybar.enable = true;
        };
    };
}
