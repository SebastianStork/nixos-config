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
      metrics = {
        system = lib.mkEnableOption "";
        victorialogs = lib.mkEnableOption "";
      };
      logs.sshd = lib.mkEnableOption "";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.collect.metrics.victorialogs -> config.services.victorialogs.enable;
        message = "Collecting VictoriaLogs metrics requires the VictoriaLogs service to be enabled.";
      }
      {
        assertion = cfg.collect.logs.sshd -> config.services.openssh.enable;
        message = "Collecting OpenSSH logs requires the OpenSSH service to be enabled.";
      }
    ];

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

    environment.etc =
      let
        isTrue = x: x;
        anyIsTrue = attrs: attrs |> lib.attrValues |> lib.any isTrue;
      in
      {
        "alloy/metrics-endpoint.alloy" = {
          enable = cfg.collect.metrics |> anyIsTrue;
          text = ''
            prometheus.remote_write "default" {
              endpoint {
                url = "${cfg.metricsEndpoint}"
              }
            }
          '';
        };
        "alloy/logs-endpoint.alloy" = {
          enable = cfg.collect.logs |> anyIsTrue;
          text = ''
            loki.write "default" {
              endpoint {
                url = "${cfg.logsEndpoint}"
              }
            }
          '';
        };
        "alloy/system-metrics.alloy" = {
          enable = cfg.collect.metrics.system;
          text = ''
            prometheus.exporter.unix "default" {
              enable_collectors = ["systemd"]
            }

            prometheus.scrape "node_exporter" {
              targets         = prometheus.exporter.unix.default.targets
              forward_to      = [prometheus.remote_write.default.receiver]
              scrape_interval = "15s"
            }
          '';
        };
        "alloy/victorialogs-metrics.alloy" = {
          enable = cfg.collect.metrics.victorialogs;
          text = ''
            prometheus.scrape "victorialogs" {
              targets = [{
                __address__ = "localhost:${builtins.toString config.custom.services.victorialogs.port}",
                job         = "victorialogs",
                instance    = constants.hostname,
              }]
              forward_to      = [prometheus.remote_write.default.receiver]
              scrape_interval = "15s"
            }
          '';
        };
        "alloy/sshd-logs.alloy" = {
          enable = cfg.collect.logs.sshd;
          text = ''
            loki.source.journal "sshd" {
              matches    = "_SYSTEMD_UNIT=sshd.service"
              forward_to = [loki.write.default.receiver]
            }
          '';
        };
      };
  };
}
