{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.filebrowser;

  dataDir = "/var/lib/filebrowser";
in
{
  options.custom.web-services.filebrowser = {
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
      assertion = self.lib.isPrivateDomain cfg.domain;
      message = self.lib.mkUnprotectedMessage "Filebrowser";
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
