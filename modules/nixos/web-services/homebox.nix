{ config, lib, ... }:
let
  cfg = config.custom.web-services.homebox;
  dataDir = config.services.homebox.settings.HOME;
in
{
  options.custom.web-services.homebox = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 7745;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    services.homebox = {
      enable = true;
      settings = {
        HBOX_WEB_PORT = toString cfg.port;
        HBOX_WEB_HOST = "127.0.0.1";
        HBOX_OPTIONS_TRUST_PROXY = "true";
        HBOX_OPTIONS_ALLOW_REGISTRATION = "true";
      };
    };

    custom = {
      services = {
        caddy.virtualHosts.${cfg.domain}.port = cfg.port;

        restic.backups.homebox = lib.mkIf cfg.doBackups {
          conflictingService = "homebox.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];

      meta.sites.${cfg.domain} = {
        title = "HomeBox";
        icon = "sh:homebox";
      };
    };
  };
}
