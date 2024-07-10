{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
assembleWrapper {
  basePackage = pkgs.waybar;
  flags = [
    "--config"
    ./config.json
    "--style"
    ./style.css
  ];
}
