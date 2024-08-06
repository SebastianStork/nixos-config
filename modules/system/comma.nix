{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.myConfig.comma;
in
{
  imports = [ inputs.nix-index-database.nixosModules.nix-index ];

  options.myConfig.comma.enable = lib.mkEnableOption "";

  config = {
    programs = {
      command-not-found.enable = !cfg.enable;
      nix-index.enable = cfg.enable;
      nix-index-database.comma.enable = cfg.enable;
    };
  };
}
