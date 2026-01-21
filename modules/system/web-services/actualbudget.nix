{ config, lib, ... }:
let
  cfg = config.custom.web-services.actualbudget;

  inherit (config.services.actual.settings) dataDir;
in
{
  options.custom.web-services.actualbudget = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5006;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.actual = {
        isSystemUser = true;
        group = config.users.groups.actual.name;
      };
      groups.actual = { };
    };

    systemd.services.actual.serviceConfig = {
      DynamicUser = lib.mkForce false;
      PrivateTmp = true;
      RemoveIPC = true;
    };

    services.actual = {
      enable = true;
      settings = {
        hostname = "localhost";
        inherit (cfg) port;
      };
    };

    custom = {
      services = {
        caddy.virtualHosts.${cfg.domain}.port = cfg.port;

        restic.backups.actual = lib.mkIf cfg.doBackups {
          conflictingService = "actual.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];
    };
  };
}
