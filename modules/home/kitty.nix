{
    config,
    lib,
    ...
}: {
    options.myConfig.kitty.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.kitty.enable {
        programs.kitty = {
            enable = true;

            settings = {
                font_family = "JetBrainsMono Nerd Font";
                confirm_os_window_close = 0;
                background_opacity = "0.85";
                enable_audio_bell = false;
                update_check_interval = 0;
            };

            theme =
                {
                    dark = "Default";
                    light = "Adwaita light";
                }
                ."${config.myConfig.de.theme}";
        };
    };
}
