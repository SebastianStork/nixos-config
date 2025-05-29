{ config, ... }:
{
  system.stateVersion = "24.11";

  custom = {
    sops.enable = true;
    boot.loader.systemdBoot.enable = true;

    services = {
      tailscale = {
        enable = true;
        ssh.enable = true;
        exitNode.enable = true;
      };

      syncthing = {
        enable = true;
        deviceId = "5R2MH7T-Q2ZZS2P-ZMSQ2UJ-B6VBHES-XYLNMZ6-7FYC27L-4P7MGJ2-FY4ITQD";
        isServer = true;
        backups.enable = true;
      };

      nextcloud = {
        enable = true;
        domain = "cloud.${config.custom.services.tailscale.domain}";
        backups.enable = true;
      };
      actualbudget = {
        enable = true;
        domain = "budget.${config.custom.services.tailscale.domain}";
        backups.enable = true;
      };

      caddy.virtualHosts = {
        nextcloud = {
          inherit (config.custom.services.nextcloud) domain port;
        };
        actualbudget = {
          inherit (config.custom.services.actualbudget) domain port;
        };
      };
    };
  };
}
