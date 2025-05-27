{ config, lib, ... }@moduleArgs:
{
  options.custom.deUtils.services.gammastep.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.deUtils.services.gammastep.enable {
    assertions = [
      {
        assertion =
          let
            inherit (moduleArgs.osConfig.services) geoclue2;
          in
          geoclue2.enable or true && geoclue2.appConfig.gammastep.isAllowed or true;
        message = "gammastep requires geoclue";
      }
    ];

    services.gammastep = {
      enable = true;
      provider = "geoclue2";
      settings.general.adjustment-method = "wayland";

      temperature.night = 2700;
    };
  };
}
