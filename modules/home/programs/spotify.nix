{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.spotify.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.spotify.enable {
    home.packages = [ pkgs.spotify ];
  };
}
