{ config, ... }:
let
  inherit (config) myConfig;
  inherit (config.myConfig.tailscale) caddyServe;
in
{
  system.stateVersion = "24.11";

  myConfig = {
    boot.loader.systemdBoot.enable = true;
    sops.enable = true;

    tailscale = {
      enable = true;
      ssh.enable = true;
      exitNode.enable = true;

      serve = {
        isFunnel = true;
        target = "localhost:${toString myConfig.hedgedoc.port}";
      };

      caddyServe = {
        nextcloud = {
          subdomain = "cloud";
          inherit (myConfig.nextcloud) port;
        };
        actualbudget = {
          subdomain = "budget";
          inherit (myConfig.actualbudget) port;
        };
      };
    };

    hedgedoc = {
      enable = true;
      subdomain = config.networking.hostName;
      backups.enable = true;
    };
    nextcloud = {
      enable = true;
      inherit (caddyServe.nextcloud) subdomain;
      backups.enable = true;
    };
    actualbudget = {
      enable = true;
      inherit (caddyServe.actualbudget) subdomain;
      backups.enable = true;
    };
    syncthing = {
      enable = true;
      deviceId = "5R2MH7T-Q2ZZS2P-ZMSQ2UJ-B6VBHES-XYLNMZ6-7FYC27L-4P7MGJ2-FY4ITQD";
      isServer = true;
      backups.enable = true;
    };
  };
}
