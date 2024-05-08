{
    assembleWrapper,
    pkgs,
    lib,
    ...
}: {theme ? "dark"}:
assembleWrapper {
    basePackage = pkgs.rofi-wayland;

    flags = let
        kitty-config =
            {
                dark = ./dark-config.rasi;
                light = ./light-config.rasi;
            }
            .${theme};
    in [
        "-config"
        kitty-config
    ];
}
