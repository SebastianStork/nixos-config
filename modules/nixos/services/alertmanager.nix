{
  config,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.alertmanager;
in
{
  options.custom.services.alertmanager = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9093;
    };
    clusterPort = lib.mkOption {
      type = lib.types.port;
      default = 9094;
    };
    ntfyBridgePort = lib.mkOption {
      type = lib.types.port;
      default = 11512;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      prometheus.alertmanager = {
        enable = true;

        listenAddress = "localhost";
        inherit (cfg) port;
        webExternalUrl = "https://${cfg.domain}";

        extraFlags = [
          "--cluster.advertise-address=${config.custom.networking.overlay.address}:${toString cfg.clusterPort}"
          "--cluster.listen-address=${config.custom.networking.overlay.address}:${toString cfg.clusterPort}"
        ]
        ++ (
          allHosts
          |> lib.attrValues
          |> lib.filter (host: host.config.networking.hostName != config.networking.hostName)
          |> lib.filter (host: host.config.custom.services.alertmanager.enable)
          |> lib.map (
            host: "--cluster.peer ${host.config.custom.networking.overlay.address}:${toString cfg.clusterPort}"
          )
        );

        configuration = {
          route = {
            group_by = [
              "alertname"
              "instance"
            ];
            receiver = "ntfy";
          };
          receivers = lib.singleton {
            name = "ntfy";
            webhook_configs = lib.singleton { url = "http://localhost:${toString cfg.ntfyBridgePort}/hook"; };
          };
          inhibit_rules = lib.singleton {
            source_matchers = [
              ''alertname="InstanceDown"''
              ''job="node"''
            ];
            target_matchers = lib.singleton ''alertname!="InstanceDown"'';
            equal = [ "instance" ];
          };
        };
      };

      prometheus.alertmanager-ntfy = {
        enable = true;
        settings = {
          http.addr = "localhost:${toString cfg.ntfyBridgePort}";
          ntfy = {
            baseurl = "https://ntfy.sh";
            notification = {
              topic = "splitleaf";
              priority = "default";
              templates.title = ''{{ if eq .Status "firing" }}{{ index .Annotations "summary" }}{{ else }}{{ index .Annotations "summary_resolved" }}{{ end }}'';
              tags = [
                {
                  condition = ''status == "resolved"'';
                  tag = "white_check_mark";
                }
                {
                  condition = ''status == "firing"'';
                  tag = "rotating_light";
                }
              ];
            };
          };
        };
      };

      nebula.networks.mesh.firewall.inbound = lib.singleton {
        port = cfg.clusterPort;
        proto = "any";
        group = "server";
      };
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      meta.sites.${cfg.domain} = {
        title = "Alertmanager";
        icon = "sh:prometheus";
      };
    };
  };
}
