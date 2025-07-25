{ config, ... }:
{
  system.stateVersion = "24.11";

  meta = {
    domains.assertUnique = true;
    ports.assertUnique = true;
  };

  custom = {
    sops = {
      enable = true;
      agePublicKey = "age1dnpwfwh0h95r63e5qfjc2gvffw2tr2tx4new7sq2h3qs90kx9fmq322mx4";
    };
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
        doBackups = true;
        domain = "docs.sprouted.cloud";
      };
      it-tools = {
        enable = true;
        domain = "tools.sprouted.cloud";
      };
      forgejo = {
        enable = true;
        doBackups = true;
        domain = "git.sstork.dev";
        ssh.enable = true;
      };

      caddy.virtualHosts = {
        hedgedoc = {
          inherit (config.custom.services.hedgedoc) domain port;
        };
        it-tools = {
          inherit (config.custom.services.it-tools) domain port;
        };
        forgejo = {
          inherit (config.custom.services.forgejo) domain port;
        };
      };
    };
  };
}
