{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.nemo.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.nemo.enable {
    home.packages = [ pkgs.nemo-with-extensions ];
  };
}
