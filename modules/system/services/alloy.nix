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
        system = lib.mkEnableOption "" // {
          default = true;
        };
        victorialogs = lib.mkEnableOption "" // {
          default = config.services.victorialogs.enable;
        };
        caddy = lib.mkEnableOption "" // {
          default = config.services.caddy.enable;
        };
        crowdsec = lib.mkEnableOption "" // {
          default = config.services.crowdsec.enable;
        };
      };
      logs.openssh = lib.mkEnableOption "" // {
        default = config.services.openssh.enable;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      let
        metricsAssertions =
          cfg.collect.metrics
          |> lib.attrNames
          |> lib.filter (name: name != "system")
          |> lib.map (name: {
            assertion = cfg.collect.metrics.${name} -> config.services.${name}.enable;
            message = "Collecting ${name} metrics requires the ${name} service to be enabled.";
          });
        logsAssertions =
          cfg.collect.logs
          |> lib.attrNames
          |> lib.map (name: {
            assertion = cfg.collect.logs.${name} -> config.services.${name}.enable;
            message = "Collecting ${name} logs requires the ${name} service to be enabled.";
          });
      in
      metricsAssertions ++ logsAssertions;

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
        "alloy/caddy-metrics.alloy" = {
          enable = cfg.collect.metrics.caddy;
          text = ''
            prometheus.scrape "caddy" {
              targets = [{
                __address__ = "localhost:${builtins.toString config.custom.services.caddy.metricsPort}",
                job         = "caddy",
                instance    = constants.hostname,
              }]
              forward_to      = [prometheus.remote_write.default.receiver]
              scrape_interval = "15s"
            }
          '';
        };
        "alloy/crowdsec-metrics.alloy" = {
          enable = cfg.collect.metrics.crowdsec;
          text = ''
            prometheus.scrape "crowdsec" {
              targets = [{
                __address__ = "localhost:${builtins.toString config.custom.services.crowdsec.prometheusPort}",
                job         = "crowdsec",
                instance    = constants.hostname,
              }]
              forward_to      = [prometheus.remote_write.default.receiver]
              scrape_interval = "15s"
            }
          '';
        };
        "alloy/sshd-logs.alloy" = {
          enable = cfg.collect.logs.openssh;
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
