{ config, ... }:
let
  tsDomain = config.custom.services.tailscale.domain;
  portOf = service: config.custom.services.${service}.port;
in
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

        serve = {
          isFunnel = true;
          target = toString ./hedgedoc-redirect.html;
        };

        caddyServe = {
          nextcloud = {
            subdomain = "cloud";
            port = portOf "nextcloud";
          };
          actualbudget = {
            subdomain = "budget";
            port = portOf "actualbudget";
          };
          forgejo = {
            subdomain = "git";
            port = portOf "forgejo";
          };
        };
      };

      nextcloud = {
        enable = true;
        domain = "cloud.${tsDomain}";
        backups.enable = true;
      };
      actualbudget = {
        enable = true;
        domain = "budget.${tsDomain}";
        backups.enable = true;
      };
      forgejo = {
        enable = true;
        domain = "git.${tsDomain}";
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
