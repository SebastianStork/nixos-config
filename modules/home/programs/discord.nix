{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.discord.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.discord.enable {
    home.packages = [ pkgs.discord ];
  };
}
