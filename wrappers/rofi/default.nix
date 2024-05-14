{
    assembleWrapper,
    pkgs,
    lib,
    ...
}: {theme ? "dark"}:
assembleWrapper {
    basePackage = pkgs.rofi-wayland;

    flags = let
        color-file =
            {
                dark = ./dark.rasi;
                light = ./light.rasi;
            }
            .${theme};
        rofi-config = pkgs.concatText "rofi-config" [./config.rasi color-file];
    in [
        "-config"
        rofi-config
    ];
}
