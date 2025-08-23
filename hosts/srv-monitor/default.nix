{ config, ... }:
{
  system.stateVersion = "24.11";

  meta = {
    domains.assertUnique = true;
    ports.assertUnique = true;
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
        customEndpoints = {
          "alerts" = {
            group = "Monitoring";
            url = "https://${config.custom.services.ntfy.domain}/v1/health";
            extraConditions = [ "[BODY].healthy == true" ];
          };
          "git ssh".url = "ssh://git.sstork.dev";
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

      caddy.virtualHosts = {
        gatus = {
          inherit (config.custom.services.gatus) domain port;
        };
        ntfy = {
          inherit (config.custom.services.ntfy) domain port;
        };
        grafana = {
          inherit (config.custom.services.grafana) domain port;
        };
        victorialogs = {
          inherit (config.custom.services.victorialogs) domain port;
        };
      };
    };
  };
}
