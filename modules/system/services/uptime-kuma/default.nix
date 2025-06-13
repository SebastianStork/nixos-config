{ config, lib, ... }:
let
  cfg = config.custom.services.uptimeKuma;
in
{
  options.custom.services.uptimeKuma = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3001;
    };
  };

  config = lib.mkIf cfg.enable {
    services.uptime-kuma = {
      enable = true;
      settings.PORT = toString cfg.port;
    };
  };
}
