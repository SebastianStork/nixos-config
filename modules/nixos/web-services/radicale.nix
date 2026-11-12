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
    ownerUsername = lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9_-]+";
      default = "seb";
    };
    allowHermes = lib.mkEnableOption "";
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
      rights = lib.mkIf cfg.allowHermes {
        "00-root" = {
          user = ".+";
          collection = "";
          permissions = "R";
        };
        "10-owner-principal" = {
          user = cfg.ownerUsername;
          collection = cfg.ownerUsername;
          permissions = "RW";
        };
        "11-owner-calendars" = {
          user = cfg.ownerUsername;
          collection = "${cfg.ownerUsername}/[^/]+";
          permissions = "rw";
        };
        "20-hermes-owner-principal" = {
          user = "hermes";
          collection = cfg.ownerUsername;
          permissions = "R";
        };
        "21-hermes-writable-calendars" = {
          user = "hermes";
          collection = "${cfg.ownerUsername}/hermes[^/]*";
          permissions = "rw";
        };
        "22-hermes-owner-calendars" = {
          user = "hermes";
          collection = "${cfg.ownerUsername}/[^/]+";
          permissions = "r";
        };
      };
    };

    custom = {
      services = {
        caddy.virtualHosts.${cfg.domain} = {
          inherit (cfg) port;
          extraAllowedGroups = lib.optional cfg.allowHermes "agent";
        };

        restic.backups.radicale = lib.mkIf cfg.doBackups {
          conflictingService = "radicale.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];

      meta.sites.${cfg.domain} = {
        title = "Radicale";
        icon = "radicale";
      };
    };
  };
}
