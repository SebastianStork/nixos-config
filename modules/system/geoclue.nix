{ config, lib, ... }:
{
  options.custom.services.geoclue.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.geoclue.enable {
    services.geoclue2 = {
      enable = true;

      appConfig.gammastep = {
        isAllowed = true;
        isSystem = false;
      };
    };
  };
}
