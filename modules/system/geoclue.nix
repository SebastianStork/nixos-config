{ config, lib, ... }:
{
  options.myConfig.geoclue.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.geoclue.enable {
    services.geoclue2 = {
      enable = true;
      geoProviderUrl = "https://beacondb.net/v1/geolocate";
      
      appConfig.gammastep = {
        isAllowed = true;
        isSystem = false;
      };
    };
  };
}
