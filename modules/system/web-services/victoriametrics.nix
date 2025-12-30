{ config, lib, ... }:
let
  cfg = config.custom.web-services.victoriametrics;
in
{
  options.custom.web-services.victoriametrics = {
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
    meta = {
      domains.local = [ cfg.domain ];
      ports.tcp = [ cfg.port ];
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
      listenAddress = "localhost:${toString cfg.port}";
      extraOptions = [
        "-selfScrapeInterval=15s"
        "-selfScrapeJob=victoriametrics"
        "-selfScrapeInstance=${config.networking.hostName}"
      ];
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      persistence.directories = [ "/var/lib/${config.services.victoriametrics.stateDir}" ];
    };
  };
}
