{ config, ... }:
{
  system.stateVersion = "24.11";

  custom = {
    sops.enable = true;
    boot.loader.grub.enable = true;

    services = {
      tailscale = {
        enable = true;
        ssh.enable = true;
      };

      crowdsec = {
        enable = true;
        firewallBouncer.enable = true;
        sources = [
          "iptables"
          "caddy"
        ];
      };

      hedgedoc = {
        enable = true;
        domain = "docs.sprouted.cloud";
        backups.enable = true;
      };
      forgejo = {
        enable = true;
        domain = "git.sstork.dev";
        ssh.enable = true;
      };

      caddy.virtualHosts = {
        hedgedoc = {
          inherit (config.custom.services.hedgedoc) domain port;
        };
        forgejo = {
          inherit (config.custom.services.forgejo) domain port;
        };
      };
    };
  };
}
