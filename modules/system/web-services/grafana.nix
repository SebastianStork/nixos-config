{
  config,
  pkgs,
  lib,
  ...
}:
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
    datasources = {
      prometheus = {
        enable = lib.mkEnableOption "";
        url = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "https://metrics.${config.custom.services.tailscale.domain}";
        };
      };
      victoriametrics = {
        enable = lib.mkEnableOption "";
        url = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "https://metrics.${config.custom.services.tailscale.domain}";
        };
      };
      victorialogs = {
        enable = lib.mkEnableOption "";
        url = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "https://logs.${config.custom.services.tailscale.domain}";
        };
      };
    };
    dashboards = {
      nodeExporter.enable = lib.mkEnableOption "";
      victoriametrics.enable = lib.mkEnableOption "";
      victorialogs.enable = lib.mkEnableOption "";
      crowdsec.enable = lib.mkEnableOption "";
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
          datasources = lib.concatLists [
            (lib.optional cfg.datasources.prometheus.enable {
              name = "Prometheus";
              type = "prometheus";
              inherit (cfg.datasources.prometheus) url;
              isDefault = true;
              jsonData = {
                prometheusType = "Prometheus";
                prometheusVersion = "2.50.0";
              };
            })
            (lib.optional cfg.datasources.victoriametrics.enable {
              name = "VictoriaMetrics";
              type = "victoriametrics-metrics-datasource";
              inherit (cfg.datasources.victoriametrics) url;
              isDefault = false;
            })
            (lib.optional cfg.datasources.victorialogs.enable {
              name = "VictoriaLogs";
              type = "victoriametrics-logs-datasource";
              inherit (cfg.datasources.victorialogs) url;
              isDefault = false;
            })
          ];
        };
      };

      declarativePlugins =
        let
          plugins = pkgs.grafanaPlugins;
        in
        [
          (lib.optional cfg.datasources.victoriametrics.enable plugins.victoriametrics-metrics-datasource)
          (lib.optional cfg.datasources.victorialogs.enable plugins.victoriametrics-logs-datasource)
        ]
        |> lib.concatLists;
    };

    environment.etc = {
      # https://grafana.com/grafana/dashboards/1860-node-exporter-full/
      "grafana-dashboards/node-exporter-full.json" = {
        enable = cfg.dashboards.nodeExporter.enable;
        source = pkgs.fetchurl {
          name = "node-exporter-full.json";
          url = "https://grafana.com/api/dashboards/1860/revisions/41/download";
          hash = "sha256-EywgxEayjwNIGDvSmA/S56Ld49qrTSbIYFpeEXBJlTs=";
        };
      };
      # https://grafana.com/grafana/dashboards/10229-victoriametrics-single-node/
      "grafana-dashboards/victoriametrics-single-node.json" = {
        enable = cfg.dashboards.victoriametrics.enable;
        source = pkgs.fetchurl {
          name = "victoriametrics-single-node.json";
          url = "https://grafana.com/api/dashboards/10229/revisions/41/download";
          hash = "sha256-mwtah8A2w81WZjf5bUXoTJfS1R9UX+tua2PiDrBKJCQ=";
        };
      };
      # https://grafana.com/grafana/dashboards/22084-victorialogs-single-node/
      "grafana-dashboards/victorialogs-single-node.json" = {
        enable = cfg.dashboards.victorialogs.enable;
        source = pkgs.fetchurl {
          name = "victorialogs-single-node.json";
          url = "https://grafana.com/api/dashboards/22084/revisions/8/download";
          hash = "sha256-/a3Rbp/6oyiLBnQtGupyFZW+fIHQfkyKRRTyfofxVTM=";
        };
      };
      # https://grafana.com/grafana/dashboards/19012-crowdsec-details-per-instance/
      "grafana-dashboards/crowdsec-details-per-instance.json" = {
        enable = cfg.dashboards.crowdsec.enable;
        source =
          pkgs.fetchurl {
            name = "crowdsec-details-per-instance.json";
            url = "https://grafana.com/api/dashboards/19012/revisions/1/download";
            hash = "sha256-VRPWAbPRgp+2pqfmey53wMqaOhLBzXVKUZs/pJ28Ikk=";
          }
          |> (
            src:
            pkgs.runCommand "crowdsec-details-per-instance-patched.json" { buildInputs = [ pkgs.gnused ]; } ''
              sed 's/''${DS_PROMETHEUS}/Prometheus/g' ${src} > $out
            ''
          );
      };
    };
  };
}
