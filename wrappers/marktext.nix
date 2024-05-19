{ assembleWrapper, pkgs, ... }:
assembleWrapper {
  basePackage = pkgs.marktext;
  flags = [ "--disable-gpu" ];
}
