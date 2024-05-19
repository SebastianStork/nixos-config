{ assembleWrapper, pkgs, ... }:
assembleWrapper {
  basePackage = pkgs.webcord;
  flags = [ "--disable-gpu" ];
}
