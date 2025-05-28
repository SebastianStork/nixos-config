{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.rofi.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.rofi.enable {
    home.packages = [ pkgs.rofi-wayland ];

    xdg.configFile."rofi/config.rasi".source =
      let
        theming =
          {
            dark = ./dark-theme.rasi;
            light = ./light-theme.rasi;
          }
          .${config.custom.theme};
      in
      pkgs.concatText "rofi-config" [
        ./config.rasi
        theming
      ];
  };
}
