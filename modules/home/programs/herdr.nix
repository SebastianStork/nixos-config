{
  config,
  pkgs-unstable,
  lib,
  ...
}:
{
  options.custom.programs.herdr.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.herdr.enable {
    home.packages = [ pkgs-unstable.herdr ];
  };
}
