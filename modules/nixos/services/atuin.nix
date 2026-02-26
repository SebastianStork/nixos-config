{ config, lib, ... }:
let
  cfg = config.custom.services.atuin;
  dataDir = "/var/lib/atuin";
in
{
  options.custom.services.atuin = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8849;
    };
  };

  config = lib.mkIf cfg.enable {
    services.atuin = {
      enable = true;
      inherit (cfg) port;
      openRegistration = true;
      database = {
        createLocally = false;
        uri = "sqlite://${dataDir}/atuin.db";
      };
    };

    users = {
      users.atuin = {
        isSystemUser = true;
        group = config.users.groups.atuin.name;
      };
      groups.atuin = { };
    };

    systemd.services.atuin.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = config.users.users.atuin.name;
      Group = config.users.groups.atuin.name;
      StateDirectory = "atuin";
      StateDirectoryMode = "0700";
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      persistence.directories = [ dataDir ];
    };
  };
}
