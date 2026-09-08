{ config, lib, ... }:
let
  cfg = config.custom.web-services.trek;
  dataDir = "/var/lib/trek";
in
{
  options.custom.web-services.trek = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 1356;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets."trek/encryption-key" = { };
      templates."trek.env" = {
        content = "ENCRYPTION_KEY=${config.sops.placeholder."trek/encryption-key"}";
        restartUnits = [ "${config.virtualisation.oci-containers.backend}-trek.service" ];
      };
    };

    virtualisation.oci-containers.containers.trek = {
      image = "mauriceboe/trek:4";
      ports = [ "127.0.0.1:${lib.toString cfg.port}:3000" ];
      volumes = [
        "${dataDir}/data:/app/data"
        "${dataDir}/uploads:/app/uploads"
      ];
      environment = {
        NODE_ENV = "production";
        PORT = "3000";
        TZ = config.time.timeZone;
        ALLOWED_ORIGINS = "https://${cfg.domain}";
        APP_URL = "https://${cfg.domain}";
        FORCE_HTTPS = "true";
        TRUST_PROXY = "1";
      };
      environmentFiles = [ config.sops.templates."trek.env".path ];
      pull = "newer";
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir}/data 0755 root root -"
      "d ${dataDir}/uploads 0755 root root -"
    ];

    custom = {
      services = {
        caddy.virtualHosts.${cfg.domain}.port = cfg.port;

        restic.backups.trek = lib.mkIf cfg.doBackups {
          conflictingService = "${config.virtualisation.oci-containers.backend}-trek.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];

      meta.sites.${cfg.domain} = {
        title = "Trek";
        icon = "sh:trek";
      };
    };
  };
}
