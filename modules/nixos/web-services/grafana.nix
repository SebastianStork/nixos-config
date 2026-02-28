{
  config,
  pkgs,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.grafana;

  prometheusDomains =
    allHosts
    |> lib.attrValues
    |> lib.map (host: host.config.custom.services.prometheus)
    |> lib.filter (prometheus: prometheus.enable)
    |> lib.map (prometheus: prometheus.domain);
in
{
  options.custom.web-services.grafana = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };
    datasources.prometheus = {
      enable = lib.mkEnableOption "" // {
        default = prometheusDomains != [ ];
      };
      url = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "https://metrics.${config.custom.networking.overlay.fqdn}";
      };
    };
    dashboards.nodeExporter.enable = lib.mkEnableOption "" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
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

      provision = {
        enable = true;

        dashboards.settings = {
          providers = lib.singleton {
            name = "Dashboards";
            options.path = "/etc/grafana-dashboards";
          };
        };

        datasources.settings = {
          prune = true;
          datasources = lib.optional cfg.datasources.prometheus.enable {
            name = "Prometheus";
            type = "prometheus";
            inherit (cfg.datasources.prometheus) url;
            isDefault = true;
            jsonData = {
              prometheusType = "Prometheus";
              prometheusVersion = "3.7.2";
            };
          };
        };
      };

    };

    # https://grafana.com/grafana/dashboards/1860-node-exporter-full/
    environment.etc."grafana-dashboards/node-exporter-full.json" = {
      enable = cfg.dashboards.nodeExporter.enable;
      source = pkgs.fetchurl {
        name = "node-exporter-full.json";
        url = "https://grafana.com/api/dashboards/1860/revisions/41/download";
        hash = "sha256-EywgxEayjwNIGDvSmA/S56Ld49qrTSbIYFpeEXBJlTs=";
      };
    };

    custom.services.caddy = {
      virtualHosts.${cfg.domain}.port = cfg.port;

      virtualHosts."metrics.${config.custom.networking.overlay.fqdn}".extraConfig =
        let
          upstreams = prometheusDomains |> lib.map (domain: "https://${domain}") |> lib.concatStringsSep " ";
        in
        ''
          reverse_proxy ${upstreams} {
            header_up Host {upstream_hostport}
            lb_policy first
            health_uri /api/v1/status/buildinfo
          }
        '';
    };
  };
}
