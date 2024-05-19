{ assembleWrapper, pkgs, ... }:
assembleWrapper {
  basePackage = pkgs.bottom;
  flags = [ "--group" ];
}
