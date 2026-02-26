{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.freshrss;

  inherit (config.services.freshrss) dataDir;
in
{
  options.custom.web-services.freshrss = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 22055;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = self.lib.isPrivateDomain cfg.domain;
      message = self.lib.mkUnprotectedMessage "FreshRSS";
    };

    services.freshrss = {
      enable = true;
      baseUrl = "https://${cfg.domain}";
      webserver = "caddy";
      virtualHost = ":${toString cfg.port}";
      defaultUser = "seb";
      authType = "none";
    };

    custom = {
      services = {
        caddy.virtualHosts.${cfg.domain}.port = cfg.port;

        restic.backups.freshrss = lib.mkIf cfg.doBackups {
          conflictingService = "freshrss-updater.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];
    };
  };
}
