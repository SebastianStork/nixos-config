{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
assembleWrapper {
  basePackage = pkgs.hyprpaper;
  flags = [
    "--config"
    ./hyprpaper.conf
  ];
}
