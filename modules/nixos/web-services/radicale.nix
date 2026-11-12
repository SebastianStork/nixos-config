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
    calendarAgent = {
      enable = lib.mkEnableOption "calendar access for an agent account";
      ownerUsername = lib.mkOption {
        type = lib.types.strMatching "[A-Za-z0-9_-]+";
        default = "seb";
      };
      agentUsername = lib.mkOption {
        type = lib.types.strMatching "[A-Za-z0-9_-]+";
        default = "hermes";
      };
    };
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
      rights = lib.mkIf cfg.calendarAgent.enable {
        "00-root" = {
          user = ".+";
          collection = "";
          permissions = "R";
        };
        "10-owner-principal" = {
          user = cfg.calendarAgent.ownerUsername;
          collection = cfg.calendarAgent.ownerUsername;
          permissions = "RW";
        };
        "11-owner-calendars" = {
          user = cfg.calendarAgent.ownerUsername;
          collection = "${cfg.calendarAgent.ownerUsername}/[^/]+";
          permissions = "rw";
        };
        "20-agent-owner-principal" = {
          user = cfg.calendarAgent.agentUsername;
          collection = cfg.calendarAgent.ownerUsername;
          permissions = "R";
        };
        "21-agent-owner-calendars" = {
          user = cfg.calendarAgent.agentUsername;
          collection = "${cfg.calendarAgent.ownerUsername}/[^/]+";
          permissions = "r";
        };
        "30-agent-principal" = {
          user = cfg.calendarAgent.agentUsername;
          collection = cfg.calendarAgent.agentUsername;
          permissions = "RW";
        };
        "31-agent-calendars" = {
          user = cfg.calendarAgent.agentUsername;
          collection = "${cfg.calendarAgent.agentUsername}/[^/]+";
          permissions = "rw";
        };
        "40-owner-agent-principal" = {
          user = cfg.calendarAgent.ownerUsername;
          collection = cfg.calendarAgent.agentUsername;
          permissions = "R";
        };
        "41-owner-agent-calendars" = {
          user = cfg.calendarAgent.ownerUsername;
          collection = "${cfg.calendarAgent.agentUsername}/[^/]+";
          permissions = "r";
        };
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
        icon = "radicale";
      };
    };
  };
}
