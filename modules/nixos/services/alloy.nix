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
      default = "https://metrics.${config.custom.networking.overlay.domain}/prometheus/api/v1/write";
    };
    collect.metrics = {
      system = lib.mkEnableOption "" // {
        default = true;
      };
      caddy = lib.mkEnableOption "" // {
        default = config.services.caddy.enable;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      cfg.collect.metrics
      |> lib.attrNames
      |> lib.filter (name: name != "system")
      |> lib.map (name: {
        assertion = cfg.collect.metrics.${name} -> config.services.${name}.enable;
        message = "Alloy cannot collect `${name}` metrics without the `${name}` service";
      });

    services.alloy = {
      enable = true;
      extraFlags = [
        "--server.http.listen-addr=localhost:${toString cfg.port}"
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
        "alloy/caddy-metrics.alloy" = {
          enable = cfg.collect.metrics.caddy;
          text = ''
            prometheus.scrape "caddy" {
              targets = [{
                __address__ = "localhost:${toString config.custom.services.caddy.metricsPort}",
                job         = "caddy",
                instance    = constants.hostname,
              }]
              forward_to      = [prometheus.remote_write.default.receiver]
              scrape_interval = "15s"
            }
          '';
        };
      };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
