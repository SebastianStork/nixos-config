{ config, lib, ... }:
{
  options.myConfig.deUtils.gammastep.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.deUtils.gammastep.enable {
    services.gammastep = {
      enable = true;
      provider = "geoclue2";
      settings.general.adjustment-method = "wayland";

      temperature.night = 2700;
    };
  };
}
