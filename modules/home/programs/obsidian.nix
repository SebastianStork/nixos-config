{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.obsidian.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.obsidian.enable {
    home.packages = [ pkgs.obsidian ];
  };
}
