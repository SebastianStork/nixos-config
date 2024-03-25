{
    config,
    pkgs,
    lib,
    ...
}: {
    options.myConfig.rofi.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.rofi.enable {
        programs.rofi = {
            enable = true;
            package = pkgs.rofi-wayland;
            theme = ./rofi-theme.rasi;
        };
    };
}
