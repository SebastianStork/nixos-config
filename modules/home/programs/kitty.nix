{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.kitty.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.kitty.enable {
    programs.kitty = {
      enable = true;

      settings =
        let
          themeName =
            {
              dark = "default";
              light = "GitHub_Light";
            }
            .${config.custom.theme};
        in
        {
          include = "${pkgs.kitty-themes}/share/kitty-themes/themes/${themeName}.conf";
          font_family = "JetBrainsMono Nerd Font";
          background_opacity = "0.85";
          cursor_shape = "beam";
          confirm_os_window_close = 0;
          enable_audio_bell = "no";
          update_check_interval = 0;
        };
    };

    home.shellAliases.ssh = "kitten ssh";
  };
}
