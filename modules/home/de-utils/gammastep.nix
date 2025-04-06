{ config, lib, ... }@moduleArgs:
{
  options.myConfig.deUtils.gammastep.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.deUtils.gammastep.enable {
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
