{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
assembleWrapper {
  basePackage = pkgs.hyprlock;
  flags = [
    "--config"
    ./hyprlock.conf
  ];
}
