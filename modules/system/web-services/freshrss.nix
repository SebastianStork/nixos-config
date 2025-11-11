{
  config,
  lib,
  lib',
  ...
}:
let
  cfg = config.custom.services.freshrss;

  inherit (config.services.freshrss) dataDir;
in
{
  options.custom.services.freshrss = {
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
      assertion = lib'.isTailscaleDomain cfg.domain;
      message = lib'.mkUnprotectedMessage "FreshRSS";
    };

    meta = {
      domains.local = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
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

      persist.directories = [ dataDir ];
    };
  };
}
