{ config, ... }:
let
  inherit (config) myConfig;
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
          inherit (myConfig.nextcloud) subdomain port;
        };
        actualbudget = {
          inherit (myConfig.actualbudget) subdomain port;
        };
      };
    };

    nextcloud = {
      enable = true;
      backups.enable = true;
      subdomain = "cloud";
    };
    actualbudget = {
      enable = true;
      backups.enable = true;
      subdomain = "budget";
    };
    hedgedoc = {
      enable = true;
      backups.enable = true;
      subdomain = config.networking.hostName;
    };
    syncthing = {
      enable = true;
      isServer = true;
      deviceId = "5R2MH7T-Q2ZZS2P-ZMSQ2UJ-B6VBHES-XYLNMZ6-7FYC27L-4P7MGJ2-FY4ITQD";
    };
  };
}
