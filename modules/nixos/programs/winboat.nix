{
  config,
  pkgs-unstable,
  lib,
  ...
}:
{
  options.custom.programs.winboat.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.winboat.enable {
    custom.programs.docker.enable = true;

    environment.systemPackages = [ pkgs-unstable.winboat ];
  };
}
