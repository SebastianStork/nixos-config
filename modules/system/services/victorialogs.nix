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
    maxDiskSpaceUsage = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "10GiB";
    };
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
      package = pkgs-unstable.victorialogs;
      listenAddress = "localhost:${builtins.toString cfg.port}";
      extraOptions = [ "-retention.maxDiskSpaceUsageBytes=${cfg.maxDiskSpaceUsage}" ];
    };

    custom.persist.directories = [ "/var/lib/${config.services.victorialogs.stateDir}" ];
  };
}
