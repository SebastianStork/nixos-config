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
          static_configs =
            allHosts
            |> lib.attrValues
            |> lib.filter (host: host.config.custom.services.prometheus.enable)
            |> lib.map (host: {
              targets = lib.singleton host.config.custom.services.prometheus.domain;
              labels.instance = host.config.networking.hostName;
            });
        }
        {
          job_name = "alertmanager";
          static_configs =
            allHosts
            |> lib.attrValues
            |> lib.filter (host: host.config.custom.services.alertmanager.enable)
            |> lib.map (host: {
              targets = lib.singleton host.config.custom.services.alertmanager.domain;
              labels.instance = host.config.networking.hostName;
            });
        }
      ];

      ruleFiles =
        {
          groups = lib.singleton {
            name = "Rules";
            rules =
              (
                allHosts
                |> lib.attrValues
                |> lib.filter (host: host.config.custom.services.alloy.enable)
                |> lib.filter (host: host.config.custom.networking.overlay.role == "server")
                |> lib.map (host: host.config.networking.hostName)
                |> lib.map (hostName: {
                  alert = "InstanceDown";
                  expr = ''absent_over_time(up{instance="${hostName}", job="node"}[2m])'';
                  labels.severity = "critical";
                  annotations = {
                    summary = "Host ${hostName} is down";
                    summary_resolved = "Host ${hostName} is up again";
                    description = "Prometheus has not received node metrics from ${hostName} for 2 minutes.";
                    description_resolved = "Prometheus is receiving node metrics from ${hostName} again.";
                  };
                })
              )
              ++ [
                {
                  alert = "ServiceDown";
                  expr = ''up{job=~"prometheus|alertmanager"} == 0'';
                  for = "2m";
                  annotations = {
                    summary = "Service {{ $labels.job | title }} on {{ $labels.instance }} is down";
                    summary_resolved = "Service {{ $labels.job | title }} on {{ $labels.instance }} is up again";
                    description = "Prometheus has not received scrape data for 2 minutes.";
                    description_resolved = "Prometheus is receiving scrape data again.";
                  };
                }
                {
                  alert = "CominDeploymentFailed";
                  expr = ''comin_deployment_info{status!="done"}'';
                  annotations = {
                    summary = "Deployment on {{ $labels.instance }} failed";
                    summary_resolved = "Deployment on {{ $labels.instance }} succeeded again";
                    description = "Comin reports a deployment status other than \"done\".";
                    description_resolved = "Comin reports the deployment status as \"done\" again.";
                  };
                }
                {
                  alert = "CominDeploymentCommitMismatch";
                  expr = "count(count by (commit_id) (comin_deployment_info)) > 1";
                  for = "10m";
                  annotations = {
                    summary = "Deployment commits are out of sync";
                    summary_resolved = "Deployment commits are in sync again";
                    description = "Comin reports different deployed commits across hosts.";
                    description_resolved = "Comin reports the same deployed commit across all hosts again.";
                  };
                }
              ];
          };
        }
        |> lib.strings.toJSON
        |> pkgs.writeText "prometheus-rules"
        |> toString
        |> lib.singleton;
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      persistence.directories = [ "/var/lib/${config.services.prometheus.stateDir}" ];

      meta.sites.${cfg.domain} = {
        title = "Prometheus";
        icon = "sh:prometheus";
      };
    };
  };
}
