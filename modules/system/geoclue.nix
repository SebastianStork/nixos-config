{ config, lib, ... }:
{
  options.myConfig.geoclue.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.geoclue.enable {
    services.geoclue2 = {
      enable = true;

      appConfig.gammastep = {
        isAllowed = true;
        isSystem = false;
      };
    };
  };
}
