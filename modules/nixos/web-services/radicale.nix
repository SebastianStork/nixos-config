{ config, lib, ... }:
let
  cfg = config.custom.web-services.radicale;
  dataDir = config.services.radicale.settings.storage.filesystem_folder;
in
{
  options.custom.web-services.radicale = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5232;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."radicale/htpasswd" = {
      owner = config.users.users.radicale.name;
      restartUnits = [ "radicale.service" ];
    };

    services.radicale = {
      enable = true;
      settings = {
        server.hosts = "localhost:${lib.toString cfg.port}";
        auth = {
          type = "htpasswd";
          htpasswd_filename = config.sops.secrets."radicale/htpasswd".path;
          htpasswd_encryption = "bcrypt";
        };
        storage.filesystem_folder = "/var/lib/radicale/collections";
      };
    };

    custom = {
      services = {
        caddy.virtualHosts.${cfg.domain}.port = cfg.port;

        restic.backups.radicale = lib.mkIf cfg.doBackups {
          conflictingService = "radicale.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];

      meta.sites.${cfg.domain} = {
        title = "Radicale";
        icon = "sh:radicale";
      };
    };
  };
}
