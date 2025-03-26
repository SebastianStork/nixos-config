{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.deUtils.brightnessctl.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.deUtils.brightnessctl.enable {
    home.packages = [ pkgs.brightnessctl ];
  };
}
