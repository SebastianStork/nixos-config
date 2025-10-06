{ config, ... }:
{
  system.stateVersion = "25.05";

  meta = {
    domains.validate = true;
    ports.validate = true;
  };

  custom = {
    impermanence.enable = true;

    sops = {
      enable = true;
      agePublicKey = "age1rp7lrakhlnnhzcgjtut8ncamem6wjrtna3e9mgdkt3dqd9dvk3usa5tzk5";
    };

    boot.loader.systemd-boot.enable = true;

    services =
      let
        tailscaleDomain = config.custom.services.tailscale.domain;
      in
      {
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
          gui.domain = "syncthing.${tailscaleDomain}";
        };

        filebrowser = {
          enable = true;
          doBackups = true;
          domain = "files.${tailscaleDomain}";
        };

        radicale = {
          enable = true;
          doBackups = true;
          domain = "calendar.${tailscaleDomain}";
        };

        memos = {
          enable = true;
          domain = "memos.${tailscaleDomain}";
        };

        actualbudget = {
          enable = true;
          doBackups = true;
          domain = "budget.${tailscaleDomain}";
        };

        alloy = {
          enable = true;
          domain = "alloy-${config.networking.hostName}.${tailscaleDomain}";
        };

        caddy.virtualHosts =
          let
            inherit (config.custom) services;
          in
          {
            syncthing-gui = {
              inherit (services.syncthing.gui) domain port;
            };
            filebrowser = {
              inherit (services.filebrowser) domain port;
            };
            radicale = {
              inherit (services.radicale) domain port;
            };
            memos = {
              inherit (services.memos) domain port;
            };
            actualbudget = {
              inherit (services.actualbudget) domain port;
            };
            alloy = {
              inherit (services.alloy) domain port;
            };
          };
      };
  };
}
