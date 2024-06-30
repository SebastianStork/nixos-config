{ config, lib, ... }:
{
  options.myConfig.night-light.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.night-light.enable {
    services.gammastep = {
      enable = true;
      provider = "geoclue2";
      settings.general.adjustment-method = "wayland";
    };
  };
}
