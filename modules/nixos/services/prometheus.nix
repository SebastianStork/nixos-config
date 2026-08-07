{
  config,
  pkgs,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.prometheus;

  allowedGroups = [
    "client"
    "server"
    "agent"
  ];
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
    services = {
      prometheus = {
        enable = true;
        stateDir = "prometheus";

        listenAddress = "0.0.0.0";
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
                    expr = ''absent_over_time(up{instance="${hostName}", job="node"}[5m])'';
                    annotations = {
                      summary = "Host ${hostName} is down";
                      summary_resolved = "Host ${hostName} is up again";
                      description = "Prometheus has not received node metrics from ${hostName} for 5 minutes.";
                      description_resolved = "Prometheus is receiving node metrics from ${hostName} again.";
                    };
                  })
                )
                ++ lib.singleton {
                  alert = "ServiceDown";
                  expr = ''up{job=~"prometheus|alertmanager"} == 0'';
                  for = "5m";
                  annotations = {
                    summary = "Service {{ $labels.job | title }} on {{ $labels.instance }} is down";
                    summary_resolved = "Service {{ $labels.job | title }} on {{ $labels.instance }} is up again";
                    description = "Prometheus has not received scrape data for 5 minutes.";
                    description_resolved = "Prometheus is receiving scrape data again.";
                  };
                }
                ++ lib.singleton {
                  alert = "PersistVolumeNearlyFull";
                  expr = ''100 * (1 - node_filesystem_avail_bytes{job="node", mountpoint="/persist"} / node_filesystem_size_bytes{job="node", mountpoint="/persist"}) > 90'';
                  for = "10m";
                  annotations = {
                    summary = "/persist on {{ $labels.instance }} is over 90% full";
                    summary_resolved = "/persist on {{ $labels.instance }} is below 90% full again";
                    description = ''The /persist volume on {{ $labels.instance }} has been above 90% usage for 10 minutes (currently {{ printf "%.1f" $value }}%).'';
                    description_resolved = ''The /persist volume on {{ $labels.instance }} is back below 90% usage (currently {{ printf "%.1f" $value }}%).'';
                  };
                };
            };
          }
          |> lib.strings.toJSON
          |> pkgs.writeText "prometheus-rules"
          |> lib.toString
          |> lib.singleton;
      };

      nebula.networks.mesh.firewall.inbound =
        allowedGroups
        |> lib.map (group: {
          inherit (cfg) port;
          proto = "tcp";
          inherit group;
        });
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
