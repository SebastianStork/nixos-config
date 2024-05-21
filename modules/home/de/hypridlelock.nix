{
  config,
  pkgs,
  lib,
  wrappers,
  ...
}:
{
  options.myConfig.de.hypridlelock.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.hypridlelock.enable {
    services.hypridle = {
      enable = true;
      package = wrappers.hypridle { };
    };
  };
}
