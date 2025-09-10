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
      agePublicKey = "age1dnpwfwh0h95r63e5qfjc2gvffw2tr2tx4new7sq2h3qs90kx9fmq322mx4";
    };

    boot.loader.grub.enable = true;

    services = {
      resolved.enable = true;
      tailscale = {
        enable = true;
        ssh.enable = true;
      };

      crowdsec = {
        enable = true;
        sources = {
          iptables = true;
          sshd = true;
          caddy = true;
        };
        bouncer.firewall = true;
      };

      forgejo = {
        enable = true;
        doBackups = true;
        domain = "git.sstork.dev";
        ssh.enable = true;
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

      stirling-pdf = {
        enable = true;
        domain = "pdf.sprouted.cloud";
      };

      privatebin = {
        enable = true;
        domain = "pastebin.sprouted.cloud";
      };

      openspeedtest = {
        enable = true;
        domain = "speedtest.sprouted.cloud";
      };

      caddy.virtualHosts =
        let
          inherit (config.custom) services;
        in
        {
          forgejo = {
            inherit (services.forgejo) domain port;
          };
          hedgedoc = {
            inherit (services.hedgedoc) domain port;
          };
          it-tools = {
            inherit (services.it-tools) domain port;
          };
          stirling-pdf = {
            inherit (services.stirling-pdf) domain port;
          };
          privatebin = {
            inherit (services.privatebin) domain port;
          };
          openspeedtest = {
            inherit (services.openspeedtest) domain port;
            tls = false;
            extraReverseProxyConfig = ''
              request_buffers 35MiB
              response_buffers 35MiB
              flush_interval -1
            '';
          };
        };
    };
  };
}
