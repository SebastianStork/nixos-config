{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.deUtils.rofi.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.deUtils.rofi.enable {
    home.packages = [ pkgs.rofi-wayland ];

    xdg.configFile."rofi/config.rasi".source =
      let
        theming =
          {
            dark = ./dark-theme.rasi;
            light = ./light-theme.rasi;
          }
          .${config.myConfig.theme};
      in
      pkgs.concatText "rofi-config" [
        ./config.rasi
        theming
      ];
  };
}
