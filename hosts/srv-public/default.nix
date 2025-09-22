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
      agePublicKey = "age1g9fm9w3j2ep7qrqmq9wx09p3ynn3xm7elp36eursj2fvh6yw5q6st448jz";
    };

    boot.loader.grub.enable = true;

    services =
      let
        sproutedDomain = "sprouted.cloud";
      in
      {
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
          bouncers.firewall = true;
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
          domain = "docs.${sproutedDomain}";
        };

        outline = {
          enable = true;
          domain = "wiki.${sproutedDomain}";
        };

        it-tools = {
          enable = true;
          domain = "tools.${sproutedDomain}";
        };

        stirling-pdf = {
          enable = true;
          domain = "pdf.${sproutedDomain}";
        };

        privatebin = {
          enable = true;
          domain = "pastebin.${sproutedDomain}";
        };

        openspeedtest = {
          enable = true;
          domain = "speedtest.${sproutedDomain}";
        };

        alloy = {
          enable = true;
          domain = "alloy-${config.networking.hostName}.${config.custom.services.tailscale.domain}";
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
            outline = {
              inherit (services.outline) domain port;
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
            alloy = {
              inherit (services.alloy) domain port;
            };
          };
      };
  };
}
