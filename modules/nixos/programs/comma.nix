{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  nixIndexPackages = inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.custom.programs.comma.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.comma.enable {
    environment = {
      systemPackages = [ nixIndexPackages.comma-with-db ];
      variables = {
        COMMA_CACHING = "1";
        COMMA_NIXPKGS_FLAKE = "pkgs-unstable";
      };
    };
  };
}
