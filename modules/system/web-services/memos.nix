{
  config,
  options,
  modulesPath,
  inputs,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.services.memos;

  dataDir = config.services.memos.settings.MEMOS_DATA;
in
{
  options.custom.services.memos = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5230;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.local = [ cfg.domain ];
      ports.tcp = [ cfg.port ];
    };

    services.memos = {
      enable = true;
      settings = options.services.memos.settings.default // {
        MEMOS_PORT = toString cfg.port;
        MEMOS_INSTANCE_URL = "https://${cfg.domain}";
      };
    };

    custom = {
      services = {
        caddy.virtualHosts.${cfg.domain}.port = cfg.port;

        restic.backups.memos = lib.mkIf cfg.doBackups {
          conflictingService = "memos.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];
    };
  };
}
