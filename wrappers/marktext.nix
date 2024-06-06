{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
assembleWrapper {
  basePackage = pkgs.marktext;
  flags = [ "--disable-gpu" ];
}
