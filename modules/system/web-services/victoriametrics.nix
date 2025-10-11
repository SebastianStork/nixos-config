{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.services.victoriametrics;
in
{
  options.custom.services.victoriametrics = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8428;
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional (lib.versionAtLeast lib.version "25.11") "TODO: Use victoriametrics package from stable nixpkgs";

    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    users = {
      users.victoriametrics = {
        isSystemUser = true;
        group = config.users.groups.victoriametrics.name;
      };
      groups.victoriametrics = { };
    };

    systemd.services.victoriametrics.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = config.users.users.victoriametrics.name;
      Group = config.users.groups.victoriametrics.name;
    };

    services.victoriametrics = {
      enable = true;
      # The victoriametrics grafana-dashboard expects the version label to have the format `victoria-metrics-*`
      package = pkgs-unstable.victoriametrics.overrideAttrs (
        _: previousAttrs: {
          version = "victoria-metrics-${previousAttrs.version}";
          __intentionallyOverridingVersion = true;
        }
      );
      listenAddress = "localhost:${toString cfg.port}";
      extraOptions = [
        "-selfScrapeInterval=15s"
        "-selfScrapeJob=victoriametrics"
        "-selfScrapeInstance=${config.networking.hostName}"
      ];
    };

    custom.persist.directories = [ "/var/lib/${config.services.victoriametrics.stateDir}" ];
  };
}
