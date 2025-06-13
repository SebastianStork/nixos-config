{ config, ... }:
{
  system.stateVersion = "24.11";

  custom = {
    sops.enable = true;
    boot.loader.grub.enable = true;

    users.seb.enable = true;

    services = {
      resolved.enable = true;
      tailscale = {
        enable = true;
        ssh.enable = true;
      };

      crowdsec = {
        enable = true;
        firewallBouncer.enable = true;
        sources = [
          "sshd"
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
        backups.enable = true;
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
