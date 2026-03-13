{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.alloy;
in
{
  options.custom.services.alloy = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 12345;
    };
    collect.metrics = {
      system = lib.mkEnableOption "" // {
        default = true;
      };
      caddy = lib.mkEnableOption "" // {
        default = config.services.caddy.enable;
      };
      comin = lib.mkEnableOption "" // {
        default = config.services.comin.enable;
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
        message = self.lib.mkInvalidConfigMessage "Alloy metric collection for `${name}`" "the `${name}` service is not enabled";
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
        anyIsTrue = attrs: attrs |> lib.attrValues |> lib.any lib.id;

        prometheusEndpoints =
          allHosts
          |> lib.attrValues
          |> lib.filter (host: host.config.custom.services.prometheus.enable)
          |> lib.map (host: "https://${host.config.custom.services.prometheus.domain}/api/v1/write");
      in
      {
        "alloy/prometheus-endpoint.alloy" = {
          enable = cfg.collect.metrics |> anyIsTrue;
          text =
            prometheusEndpoints
            |> lib.map (url: ''
              endpoint {
                url = "${url}"
              }
            '')
            |> lib.concatLines
            |> (endpoints: ''
              prometheus.remote_write "default" {
                ${endpoints}
              }
            '');
        };
        "alloy/system-metrics.alloy" = {
          enable = cfg.collect.metrics.system;
          text = ''
            prometheus.exporter.unix "default" {
              enable_collectors = ["systemd", "processes"]
            }

            discovery.relabel "node_exporter" {
              targets = prometheus.exporter.unix.default.targets
              rule {
                target_label = "job"
                replacement = "node"
              }
            }

            prometheus.scrape "node_exporter" {
              targets = discovery.relabel.node_exporter.output
              forward_to = [prometheus.remote_write.default.receiver]
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
                job = "caddy",
                instance = constants.hostname,
              }]
              forward_to = [prometheus.remote_write.default.receiver]
              scrape_interval = "30s"
            }
          '';
        };
        "alloy/comin-metrics.alloy" = {
          enable = cfg.collect.metrics.comin;
          text = ''
            prometheus.scrape "comin" {
              targets = [{
                __address__ = "localhost:${toString config.custom.services.comin.metricsPort}",
                job = "comin",
                instance = constants.hostname,
              }]
              forward_to = [prometheus.remote_write.default.receiver]
              scrape_interval = "30s"
            }
          '';
        };
      };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = lib.mkIf (cfg.domain != null) cfg.port;

      meta.sites.${cfg.domain} = lib.mkIf (cfg.domain != null) {
        title = "Alloy";
        icon = "sh:grafana-alloy";
      };
    };
  };
}
