{ config, lib, ... }:
let
  cfg = config.custom.services.alloy;
in
{
  options.custom.services.alloy = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 12345;
    };
    metricsEndpoint = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "https://metrics.${config.custom.services.tailscale.domain}/prometheus/api/v1/write";
    };
    logsEndpoint = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "https://logs.${config.custom.services.tailscale.domain}/insert/loki/api/v1/push";
    };
    collect = {
      hostMetrics = lib.mkEnableOption "";
      victorialogsMetrics = lib.mkEnableOption "";
      sshdLogs = lib.mkEnableOption "";
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    services.alloy = {
      enable = true;
      extraFlags = [
        "--server.http.listen-addr=localhost:${builtins.toString cfg.port}"
        "--disable-reporting"
      ];
    };

    environment.etc = {
      "alloy/endpoints.alloy".text = ''
        prometheus.remote_write "default" {
          endpoint {
            url = "${cfg.metricsEndpoint}"
          }
        }

        loki.write "default" {
          endpoint {
            url = "${cfg.logsEndpoint}"
          }
        }
      '';

      "alloy/host-metrics.alloy" = lib.mkIf cfg.collect.hostMetrics {
        text = ''
          prometheus.exporter.unix "default" {
            enable_collectors = ["systemd"]
          }

          prometheus.scrape "node_exporter" {
            targets = prometheus.exporter.unix.default.targets
            forward_to = [prometheus.remote_write.default.receiver]
            scrape_interval = "15s"
          }
        '';
      };

      "alloy/victorialogs-metrics.alloy" = lib.mkIf cfg.collect.victorialogsMetrics {
        text = ''
          prometheus.scrape "victorialogs" {
            targets = [{
              __address__ = "localhost:${builtins.toString config.custom.services.victorialogs.port}",
            }]
            forward_to = [prometheus.remote_write.default.receiver]
            scrape_interval = "15s"
          }
        '';
      };

      "alloy/sshd-logs.alloy" = lib.mkIf cfg.collect.sshdLogs {
        text = ''
          loki.source.journal "sshd" {
            matches = "_SYSTEMD_UNIT=sshd.service"
            forward_to = [loki.write.default.receiver]
          }
        '';
      };
    };
  };
}
