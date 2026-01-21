{ config, lib, ... }:
let
  cfg = config.custom.web-services.uptime-kuma;
in
{
  options.custom.web-services.uptime-kuma = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 44019;
    };
  };

  config = lib.mkIf cfg.enable {
    services.uptime-kuma = {
      enable = true;
      settings.PORT = toString cfg.port;
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      persistence.directories = [ config.services.uptime-kuma.settings.DATA_DIR ];
    };
  };
}
