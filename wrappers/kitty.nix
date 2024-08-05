{ inputs, pkgs, ... }:
{
  theme ? "dark",
}:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.kitty = {
        basePackage = pkgs.kitty;
        programs.kitty.prependFlags =
          let
            theme-name =
              {
                dark = "default";
                light = "GitHub_Light";
              }
              .${theme};
            kitty-config = pkgs.writeText "kitty-config" ''
              include ${pkgs.kitty-themes}/share/kitty-themes/themes/${theme-name}.conf
              font_family JetBrainsMono Nerd Font
              background_opacity 0.85
              cursor_shape beam
              confirm_os_window_close 0
              enable_audio_bell no
              update_check_interval 0
            '';
          in
          [
            "--config"
            kitty-config
          ];
      };
    }
  ];
}).config.wrappers.kitty.wrapped
