{ inputs, pkgs, ... }:
{
  theme ? "dark",
}:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.rofi = {
        basePackage = pkgs.rofi-wayland;
        flags =
          let
            theming =
              {
                dark = ./dark-theme.rasi;
                light = ./light-theme.rasi;
              }
              .${theme};
          in
          [
            "-config"
            (pkgs.concatText "rofi-config" [
              ./config.rasi
              theming
            ])
          ];
      };
    }
  ];
}).config.wrappers.rofi.wrapped
