{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.de.rofi.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.rofi.enable {
    home.packages = [ pkgs.rofi-wayland ];

    xdg.configFile."rofi/config.rasi".source =
      let
        theming =
          {
            dark = ./dark-theme.rasi;
            light = ./light-theme.rasi;
          }
          .${config.myConfig.de.theme};
      in
      pkgs.concatText "rofi-config" [
        ./config.rasi
        theming
      ];
  };
}
