{
  config,
  pkgs,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.prometheus;
in
{
  options.custom.services.prometheus = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9090;
    };
    storageRetentionSize = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "2GB";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      stateDir = "prometheus";

      listenAddress = "localhost";
      inherit (cfg) port;
      webExternalUrl = "https://${cfg.domain}";

      extraFlags = [
        "--web.enable-remote-write-receiver"
        "--storage.tsdb.retention.size=${cfg.storageRetentionSize}"
      ];
      globalConfig = {
        scrape_interval = "30s";
        external_labels.monitor = "global";
      };

      alertmanagers = lib.singleton {
        scheme = "https";
        static_configs = lib.singleton {
          targets =
            allHosts
            |> lib.attrValues
            |> lib.map (host: host.config.custom.services.alertmanager)
            |> lib.filter (alertmanager: alertmanager.enable)
            |> lib.map (alertmanager: alertmanager.domain);
        };
      };

      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = lib.singleton {
            targets =
              allHosts
              |> lib.attrValues
              |> lib.map (host: host.config.custom.services.prometheus)
              |> lib.filter (prometheus: prometheus.enable)
              |> lib.map (prometheus: prometheus.domain);
          };
        }
        {
          job_name = "alertmanager";
          static_configs = lib.singleton {
            targets =
              allHosts
              |> lib.attrValues
              |> lib.map (host: host.config.custom.services.alertmanager)
              |> lib.filter (alertmanager: alertmanager.enable)
              |> lib.map (alertmanager: alertmanager.domain);
          };
        }
      ];

      ruleFiles =
        {
          groups = lib.singleton {
            name = "Rules";
            rules = [
              {
                alert = "InstanceDown";
                expr = "up == 0";
                for = "2m";
                labels.severity = "critical";
                annotations = {
                  summary = "{{ $labels.instance }} is DOWN";
                  description = "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 2 minutes.";
                };
              }
              {
                alert = "CominDeploymentFailed";
                expr = ''comin_deployment_info{status!="done"}'';
                annotations = {
                  summary = "{{ $labels.instance }} deployment failed";
                  description = "The deployment of {{ $labels.instance }} with comin is failing.";
                };
              }
              {
                alert = "CominDeploymentCommitMismatch";
                expr = "count(count by (commit_id) (comin_deployment_info)) > 1";
                for = "10m";
                annotations = {
                  summary = "Hosts are running different commits";
                  description = "Not all hosts are running the same git commit, which may indicate a failed deployment and could lead to incompatible configurations.";
                };
              }
            ];
          };
        }
        |> lib.strings.toJSON
        |> pkgs.writeText "prometheus-instance-down-rule"
        |> toString
        |> lib.singleton;
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      persistence.directories = [ "/var/lib/${config.services.prometheus.stateDir}" ];

      meta.services.${cfg.domain} = {
        name = "Prometheus";
        icon = "sh:prometheus";
      };
    };
  };
}
