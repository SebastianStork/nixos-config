{ config, lib, ... }:
{
  options.myConfig.de.gammastep.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.gammastep.enable {
    services.gammastep = {
      enable = true;
      provider = "geoclue2";
      settings.general.adjustment-method = "wayland";

      temperature.night = 2700;
    };
  };
}
