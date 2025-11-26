{
  config,
  modulesPath,
  inputs,
  lib,
  lib',
  ...
}:
let
  cfg = config.custom.services.filebrowser;

  dataDir = "/var/lib/filebrowser";
in
{
  options.custom.services.filebrowser = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 44093;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = lib'.isTailscaleDomain cfg.domain;
      message = lib'.mkUnprotectedMessage "Filebrowser";
    };

    meta = {
      domains.local = [ cfg.domain ];
      ports.tcp = [ cfg.port ];
    };

    services.filebrowser = {
      enable = true;
      settings = {
        inherit (cfg) port;
        noauth = true;
      };
    };

    custom = {
      services = {
        caddy.virtualHosts.${cfg.domain}.port = cfg.port;

        restic.backups.filebrowser = lib.mkIf cfg.doBackups {
          conflictingService = "filebrowser.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];
    };
  };
}
