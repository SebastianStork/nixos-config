{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.victorialogs;
in
{
  options.custom.web-services.victorialogs = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9428;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.local = [ cfg.domain ];
      ports.tcp = [ cfg.port ];
    };

    users = {
      users.victorialogs = {
        isSystemUser = true;
        group = config.users.groups.victoriametrics.name;
      };
      groups.victorialogs = { };
    };

    systemd.services.victorialogs.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = config.users.users.victorialogs.name;
      Group = config.users.groups.victorialogs.name;
    };

    services.victorialogs = {
      enable = true;
      # The victorialogs grafana-dashboard expects the version label to have the format `victoria-logs-*`
      package = pkgs.victorialogs.overrideAttrs (
        _: previousAttrs: {
          version = "victoria-logs-${previousAttrs.version}";
          __intentionallyOverridingVersion = true;
        }
      );
      listenAddress = "localhost:${toString cfg.port}";
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      persistence.directories = [ "/var/lib/${config.services.victorialogs.stateDir}" ];
    };
  };
}
