{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.de;
in {
    imports = [./config.nix];

    options.myConfig.de.hyprland.enable = lib.mkEnableOption "";

    config = lib.mkIf cfg.hyprland.enable {
        home.packages = [pkgs.hyprpaper];
        xdg.configFile."hypr/hyprpaper.conf".text = ''
            preload=${cfg.wallpaper}
            wallpaper=,${cfg.wallpaper}
            splash=false
        '';

        services.cliphist.enable = true;

        services.dunst.enable = true;

        myConfig.de = {
            rofi.enable = true;
            hypridlelock.enable = true;
            waybar.enable = true;
        };
    };
}
