{ config, ... }:
{
  system.stateVersion = "24.11";

  meta = {
    domains.validate = true;
    ports.validate = true;
  };

  custom = {
    sops = {
      enable = true;
      agePublicKey = "age1dnru7l0agvnw3t9kmx60u4vh5u4tyd49xdve53zspxkznnp9f34qtec9dl";
    };

    boot.loader.grub.enable = true;

    services = {
      resolved.enable = true;
      tailscale = {
        enable = true;
        ssh.enable = true;
      };

      gatus = {
        enable = true;
        domain = "status.${config.custom.services.tailscale.domain}";
        domainsToMonitor = config.meta.domains.globalList;
        endpoints = {
          "alerts" = {
            group = "Monitoring";
            path = "/v1/health";
            extraConditions = [ "[BODY].healthy == true" ];
          };
          "grafana".group = "Monitoring";
          "logs".group = "Monitoring";
          "git ssh" = {
            protocol = "ssh";
            domain = "git.sstork.dev";
          };
          "speedtest".protocol = "http";
        };
      };

      ntfy = {
        enable = true;
        domain = "alerts.${config.custom.services.tailscale.domain}";
      };

      grafana = {
        enable = true;
        domain = "grafana.${config.custom.services.tailscale.domain}";
      };

      victorialogs = {
        enable = true;
        domain = "logs.${config.custom.services.tailscale.domain}";
      };

      caddy.virtualHosts =
        let
          inherit (config.custom) services;
        in
        {
          gatus = {
            inherit (services.gatus) domain port;
          };
          ntfy = {
            inherit (services.ntfy) domain port;
          };
          grafana = {
            inherit (services.grafana) domain port;
          };
          victorialogs = {
            inherit (services.victorialogs) domain port;
          };
        };
    };
  };
}
