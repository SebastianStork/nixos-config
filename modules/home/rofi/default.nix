{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.rofi;
in {
    options.myConfig.rofi = {
        enable = lib.mkEnableOption "";
        clipboard.enable = lib.mkEnableOption "";
    };

    config = lib.mkIf cfg.enable {
        programs.rofi = {
            enable = true;
            package = pkgs.rofi-wayland;
            theme = ./theme.rasi;
        };

        services.clipmenu = lib.mkIf cfg.clipboard.enable {
            enable = true;
            launcher = "rofi";
        };
    };
}
