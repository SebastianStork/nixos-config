{
    assembleWrapper,
    pkgs,
    lib,
    ...
}: {theme ? "dark"}:
assembleWrapper {
    basePackage = pkgs.kitty;

    flags = let
        toKittyConfig = lib.generators.toKeyValue {
            mkKeyValue = key: value: let
                value' = (
                    if lib.isBool value
                    then lib.hm.booleans.yesNo value
                    else toString value
                );
            in "${key} ${value'}";
        };
        kitty-config = pkgs.writeText "kitty-config" (toKittyConfig {
            font_family = "JetBrainsMono Nerd Font";
            confirm_os_window_close = 0;
            background_opacity = "0.85";
            enable_audio_bell = false;
            update_check_interval = 0;
            cursor_shape = "beam";
        });
        kitty-theme = pkgs.writeText "kitty-theme" "include ${pkgs.kitty-themes}/share/kitty-themes/themes/${{
            dark = "default.conf";
            light = "GitHub_Light.conf";
        }
        .${theme}}";
    in [
        "--config"
        kitty-config
        "--config"
        kitty-theme
    ];
}
