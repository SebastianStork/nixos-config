{ config, ... }:
{
  system.stateVersion = "24.11";

  custom = {
    sops.enable = true;
    boot.loader.grub.enable = true;

    users.seb.enable = true;

    services = {
      resolved.enable = true;
      tailscale = {
        enable = true;
        ssh.enable = true;
      };

      gatus = {
        enable = true;
        domain = "status.${config.custom.services.tailscale.domain}";
        endpointDomains = config.meta.domains.globalList;
        customEndpoints = {
          "status" = {
            group = "Monitoring";
            url = "https://${config.custom.services.gatus.domain}";
          };
          "alerts" = {
            group = "Monitoring";
            url = "https://alerts.${config.custom.services.tailscale.domain}/v1/health";
            extraConditions = [ "[BODY].healthy == true" ];
          };
          "git ssh".url = "ssh://git.sstork.dev";
        };
      };

      ntfy = {
        enable = true;
        domain = "alerts.${config.custom.services.tailscale.domain}";
      };

      caddy.virtualHosts = {
        gatus = {
          inherit (config.custom.services.gatus) domain port;
        };
        ntfy = {
          inherit (config.custom.services.ntfy) domain port;
        };
      };
    };
  };
}
