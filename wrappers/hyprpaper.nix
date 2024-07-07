{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
assembleWrapper {
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
}
