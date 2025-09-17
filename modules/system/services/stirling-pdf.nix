{ config, lib, ... }:
let
  cfg = config.custom.services.stirling-pdf;
in
{
  options.custom.services.stirling-pdf = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 56191;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    services.stirling-pdf = {
      enable = true;
      environment = {
        SERVER_ADDRESS = "127.0.0.1";
        SERVER_PORT = cfg.port;
        SYSTEM_ENABLEANALYTICS = "false";
        LANGS = "de_DE";
      };
    };
  };
}
