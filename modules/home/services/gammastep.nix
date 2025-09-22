{ config, lib, ... }@moduleArgs:
{
  options.custom.services.gammastep.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.gammastep.enable {
    assertions = [
      {
        assertion =
          let
            inherit (moduleArgs.osConfig.services) geoclue2;
          in
          geoclue2.enable or true && geoclue2.appConfig.gammastep.isAllowed or true;
        message = "Gammastep requires Geoclue2";
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
