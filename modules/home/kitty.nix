{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.kitty.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.kitty.enable {
    programs.kitty = {
      enable = true;

      settings =
        let
          theme-name =
            {
              dark = "default";
              light = "GitHub_Light";
            }
            .${config.myConfig.de.theme};
        in
        {
          include = "${pkgs.kitty-themes}/share/kitty-themes/themes/${theme-name}.conf";
          font_family = "JetBrainsMono Nerd Font";
          background_opacity = "0.85";
          cursor_shape = "beam";
          confirm_os_window_close = 0;
          enable_audio_bell = "no";
          update_check_interval = 0;
        };
    };
  };
}
