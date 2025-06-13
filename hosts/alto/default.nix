{ config, ... }:
{
  system.stateVersion = "24.11";

  custom = {
    sops.enable = true;
    boot.loader.systemdBoot.enable = true;

    users.seb.enable = true;

    services = {
      tailscale = {
        enable = true;
        ssh.enable = true;
        exitNode.enable = true;
      };

      syncthing = {
        enable = true;
        isServer = true;
        deviceId = "5R2MH7T-Q2ZZS2P-ZMSQ2UJ-B6VBHES-XYLNMZ6-7FYC27L-4P7MGJ2-FY4ITQD";
        gui.domain = "syncthing.${config.custom.services.tailscale.domain}";
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
        syncthing-gui = {
          inherit (config.custom.services.syncthing.gui) domain port;
        };
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
