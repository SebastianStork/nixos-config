{ config, lib, ... }:
let
  cfg = config.custom.services.uptime-kuma;
in
{
  options.custom.services.uptime-kuma = {
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
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    services.uptime-kuma = {
      enable = true;
      settings.PORT = toString cfg.port;
    };

    custom.persist.directories = [ config.services.uptime-kuma.settings.DATA_DIR ];
  };
}
