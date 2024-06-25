{ config, lib, ... }:
{
  options.myConfig.geoclue.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.geoclue.enable {
    sops.secrets.geoclue-location-service = {
      owner = "geoclue";
      path = "/etc/geoclue/conf.d/location-service.conf";
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
