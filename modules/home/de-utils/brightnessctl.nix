{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.deUtils.programs.brightnessctl.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.deUtils.programs.brightnessctl.enable {
    home.packages = [ pkgs.brightnessctl ];
  };
}
