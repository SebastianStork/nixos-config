{ config, lib, ... }:
{
  options.myConfig.night-light.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.night-light.enable {
    services.geoclue2 = {
      enable = true;
      appConfig.gammastep = {
        isAllowed = true;
        isSystem = false;
      };
    };

    home-manager.sharedModules = [
      {
        services.gammastep = {
          enable = true;
          provider = "geoclue2";
          settings.general.adjustment-method = "wayland";
        };
      }
    ];
  };
}
