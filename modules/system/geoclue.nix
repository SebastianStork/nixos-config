{ config, lib, ... }:
{
  options.myConfig.geoclue.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.geoclue.enable {
    sops = {
      secrets.geolocation-api-key = { };

      templates."geoclue-location-service.conf" = {
        owner = "geoclue";
        path = "/etc/geoclue/conf.d/location-service.conf";
        content = ''
          [wifi]
          url=https://www.googleapis.com/geolocation/v1/geolocate?key=${config.sops.placeholder.geolocation-api-key}
        '';
      };
    };

    services.geoclue2 = {
      enable = true;

      appConfig.gammastep = {
        isAllowed = true;
        isSystem = false;
      };
    };
  };
}
