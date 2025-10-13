{ config, inputs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.disko.nixosModules.default
  ];

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
          domain = "files.${tailscaleDomain}";
          doBackups = true;
        };

        radicale = {
          enable = true;
          domain = "calendar.${tailscaleDomain}";
          doBackups = true;
        };

        memos = {
          enable = true;
          domain = "memos.${tailscaleDomain}";
          doBackups = true;
        };

        actualbudget = {
          enable = true;
          domain = "budget.${tailscaleDomain}";
          doBackups = true;
        };

        freshrss = {
          enable = true;
          domain = "rss.${tailscaleDomain}";
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
            freshrss = {
              inherit (services.freshrss) domain port;
            };
            alloy = {
              inherit (services.alloy) domain port;
            };
          };
      };
  };
}
