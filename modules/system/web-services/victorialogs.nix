{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.services.victorialogs;
in
{
  options.custom.services.victorialogs = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9428;
    };
    maxDiskSpaceUsage = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "10GiB";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional (lib.versionAtLeast lib.version "25.11") "TODO: Use victorialogs package from stable nixpkgs";

    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
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
      package = pkgs-unstable.victorialogs.overrideAttrs (
        _: previousAttrs: {
          version = "victoria-logs-${previousAttrs.version}";
          __intentionallyOverridingVersion = true;
        }
      );
      listenAddress = "localhost:${toString cfg.port}";
      extraOptions = [ "-retention.maxDiskSpaceUsageBytes=${cfg.maxDiskSpaceUsage}" ];
    };

    custom.persist.directories = [ "/var/lib/${config.services.victorialogs.stateDir}" ];
  };
}
