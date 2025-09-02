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
      agePublicKey = "age1qz04yg4h4g22wxqca2pd5k0z574223f6m5c9jy5ny37nlgcd6u4styf06t";
    };

    boot.loader.systemd-boot.enable = true;

    services = {
      resolved.enable = true;
      tailscale = {
        enable = true;
        ssh.enable = true;
        exitNode.enable = true;
      };

      syncthing = {
        enable = true;
        isServer = true;
        doBackups = true;
        deviceId = "5R2MH7T-Q2ZZS2P-ZMSQ2UJ-B6VBHES-XYLNMZ6-7FYC27L-4P7MGJ2-FY4ITQD";
        gui.domain = "syncthing.${config.custom.services.tailscale.domain}";
      };

      filebrowser = {
        enable = true;
        doBackups = true;
        domain = "files.${config.custom.services.tailscale.domain}";
      };

      radicale = {
        enable = true;
        doBackups = true;
        domain = "calendar.${config.custom.services.tailscale.domain}";
      };

      actualbudget = {
        enable = true;
        doBackups = true;
        domain = "budget.${config.custom.services.tailscale.domain}";
      };

      caddy.virtualHosts = {
        syncthing-gui = {
          inherit (config.custom.services.syncthing.gui) domain port;
        };
        filebrowser = {
          inherit (config.custom.services.filebrowser) domain port;
        };
        radicale = {
          inherit (config.custom.services.radicale) domain port;
        };
        actualbudget = {
          inherit (config.custom.services.actualbudget) domain port;
        };
      };
    };
  };
}
