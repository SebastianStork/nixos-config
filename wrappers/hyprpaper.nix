{ inputs, pkgs, ... }:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.hyprpaper = {
        basePackage = pkgs.hyprpaper;
        flags =
          let
            hyprpaper-config = pkgs.writeText "hyprpaper-config" ''
              preload = ~/Pictures/.wallpaper
              wallpaper = , ~/Pictures/.wallpaper
              splash = false
            '';
          in
          [
            "--config"
            hyprpaper-config
          ];
      };
    }
  ];
}).config.wrappers.hyprpaper.wrapped
