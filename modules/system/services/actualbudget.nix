{ config, lib, ... }:
let
  cfg = config.custom.services.actualbudget;
in
{
  options.custom.services.actualbudget = {
    enable = lib.mkEnableOption "";
    doBackups = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5006;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    services.actual = {
      enable = true;
      settings = {
        hostname = "localhost";
        inherit (cfg) port;
      };
    };

    custom.services.resticBackups.actual = lib.mkIf cfg.doBackups {
      conflictingService = "actual.service";
      paths = [ config.services.actual.settings.dataDir ];
    };
  };
}
