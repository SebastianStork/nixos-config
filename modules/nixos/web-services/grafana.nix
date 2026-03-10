{
  config,
  pkgs,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.grafana;
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
          datasources =
            allHosts
            |> lib.attrValues
            |> lib.filter (host: host.config.custom.services.prometheus.enable)
            |> lib.map (host: {
              name = "Prometheus ${host.config.networking.hostName}";
              type = "prometheus";
              url = "https://${host.config.custom.services.prometheus.domain}";
              isDefault = host.config.networking.hostName == config.networking.hostName;
              jsonData = {
                prometheusType = "Prometheus";
                prometheusVersion = "3.7.2";
              };
            });
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

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      meta.sites.${cfg.domain} = {
        title = "Grafana";
        icon = "sh:grafana";
      };
    };
  };
}
