{ config, lib, ... }:
let
  cfg = config.custom.services.grafana;
in
{
  options.custom.services.grafana = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    sops.secrets."grafana/admin-password" = {
      owner = config.users.users.grafana.name;
      restartUnits = [ "grafana.service" ];
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          inherit (cfg) domain;
          http_port = cfg.port;
          enforce_domain = true;
          enable_gzip = true;
        };
        security.admin_password = "$__file{${config.sops.secrets."grafana/admin-password".path}}";
        users.default_theme = "system";
        analytics.reporting_enabled = false;
      };
    };
  };
}
