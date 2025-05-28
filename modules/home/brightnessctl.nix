{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.brightnessctl.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.brightnessctl.enable {
    home.packages = [ pkgs.brightnessctl ];
  };
}
