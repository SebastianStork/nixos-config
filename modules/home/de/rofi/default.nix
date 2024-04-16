{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.de.rofi;
in {
    options.myConfig.de.rofi = {
        enable = lib.mkEnableOption "";
    };

    config = lib.mkIf cfg.enable {
        programs.rofi = {
            enable = true;
            package = pkgs.rofi-wayland;
            theme = ./theme.rasi;
        };
    };
}
