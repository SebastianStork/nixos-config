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
    dashboards.node-exporter-full.enable = lib.mkEnableOption "";
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
          # TODO: Uncomment when upgrading to 25.11
          # prune = true;
          providers = [
            {
              name = "Dashboards";
              disableDeletion = true;
              options = {
                path = "/etc/grafana-dashboards";
                foldersFromFilesStructure = true;
              };
            }
          ];
        };

        datasources.settings = {
          # TODO: Uncomment when upgrading to 25.11
          # prune = true;
          datasources =
            (lib.optional cfg.datasources.victoriametrics.enable {
              name = "VictoriaMetrics";
              type = "victoriametrics-metrics-datasource";
              access = "proxy";
              url = "https://metrics.${config.custom.services.tailscale.domain}";
              isDefault = true;
            })
            ++ (lib.optional cfg.datasources.victorialogs.enable {
              name = "VictoriaLogs";
              type = "victoriametrics-logs-datasource";
              access = "proxy";
              url = "https://logs.${config.custom.services.tailscale.domain}";
              isDefault = false;
            });
        };
      };

      declarativePlugins =
        with pkgs.grafanaPlugins;
        (lib.optional cfg.datasources.victoriametrics.enable victoriametrics-metrics-datasource)
        ++ (lib.optional cfg.datasources.victorialogs.enable victoriametrics-logs-datasource);
    };

    environment.etc."grafana-dashboards/node-exporter-full.json".source =
      lib.mkIf cfg.dashboards.node-exporter-full.enable
        (
          pkgs.fetchurl {
            name = "node-exporter-full.json";
            url = "https://grafana.com/api/dashboards/1860/revisions/41/download";
            hash = "sha256-A6/4QjcMzkry68fSPwNdHq8i6SGwaKwZXVKDZB5h71A=";
            downloadToTemp = true;
            postFetch = ''
              patch $downloadedFile < ${./patches/node-exporter-full.patch}
              mv $downloadedFile $out
            '';
          }
        );
  };
}
