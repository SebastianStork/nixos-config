{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
assembleWrapper {
  basePackage = pkgs.waybar;
  flags = [
    "--config"
    ./config.jsonc
    "--style"
    ./style.css
  ];
}
