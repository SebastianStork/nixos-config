{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
assembleWrapper {
  basePackage = pkgs.bottom;
  flags = [ "--group" ];
}
