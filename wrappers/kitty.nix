{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
{
  theme ? "dark",
}:
assembleWrapper {
  basePackage = pkgs.kitty;
  programs.kitty.prependFlags =
    let
      kitty-config = pkgs.writeText "kitty-config" ''
        font_family JetBrainsMono Nerd Font
        background_opacity 0.85
        cursor_shape beam
        confirm_os_window_close 0
        enable_audio_bell no
        update_check_interval 0
      '';
      theme-file =
        {
          dark = "default.conf";
          light = "GitHub_Light.conf";
        }
        .${theme};
      kitty-theme = "include=${pkgs.kitty-themes}/share/kitty-themes/themes/${theme-file}";
    in
    [
      "--config"
      kitty-config
      "--override"
      kitty-theme
    ];
}
