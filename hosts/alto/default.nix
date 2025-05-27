{ config, ... }:
let
  inherit (config.custom) services;
  inherit (config.custom.services.tailscale) caddyServe;
in
{
  system.stateVersion = "24.11";

  custom = {
    boot.loader.systemdBoot.enable = true;
    sops.enable = true;

    services = {
      tailscale = {
        enable = true;
        ssh.enable = true;
        exitNode.enable = true;

        serve = {
          isFunnel = true;
          target = toString ./hedgedoc-redirect.html;
        };

        caddyServe = {
          nextcloud = {
            subdomain = "cloud";
            inherit (services.nextcloud) port;
          };
          actualbudget = {
            subdomain = "budget";
            inherit (services.actualbudget) port;
          };
          forgejo = {
            subdomain = "git";
            inherit (services.forgejo) port;
          };
        };
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
      forgejo = {
        enable = true;
        inherit (caddyServe.forgejo) subdomain;
      };

      syncthing = {
        enable = true;
        deviceId = "5R2MH7T-Q2ZZS2P-ZMSQ2UJ-B6VBHES-XYLNMZ6-7FYC27L-4P7MGJ2-FY4ITQD";
        isServer = true;
        backups.enable = true;
      };
    };
  };
}
