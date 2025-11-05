{ config, inputs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.disko.nixosModules.default
  ];

  system.stateVersion = "25.11";

  meta = {
    domains.validate = true;
    ports.validate = true;
  };

  custom = {
    impermanence.enable = true;

    sops = {
      enable = true;
      agePublicKey = "age1dv6uwnlv7d5dq63y2gwdajel3uyxxxjy07nsyth63fx2hgn3fvsqz94994";
    };

    boot.loader.grub.enable = true;

    services =
      let
        tailscaleDomain = config.custom.services.tailscale.domain;
      in
      {
        tailscale = {
          enable = true;
          ssh.enable = true;
        };

        gatus = {
          enable = true;
          domain = "status.${tailscaleDomain}";
          generateDefaultEndpoints = true;
          endpoints = {
            "alerts" = {
              path = "/v1/health";
              extraConditions = [ "[BODY].healthy == true" ];
            };
            "git ssh" = {
              group = "srv-public";
              protocol = "ssh";
              domain = "git.sstork.dev";
            };
          };
        };

        ntfy = {
          enable = true;
          domain = "alerts.${tailscaleDomain}";
        };

        grafana = {
          enable = true;
          domain = "grafana.${tailscaleDomain}";
          datasources = {
            prometheus.enable = true;
            victoriametrics.enable = true;
            victorialogs.enable = true;
          };
          dashboards = {
            nodeExporter.enable = true;
            victoriametrics.enable = true;
            victorialogs.enable = true;
            crowdsec.enable = true;
          };
        };

        victoriametrics = {
          enable = true;
          domain = "metrics.${tailscaleDomain}";
        };

        victorialogs = {
          enable = true;
          domain = "logs.${tailscaleDomain}";
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
            gatus = {
              inherit (services.gatus) domain port;
            };
            ntfy = {
              inherit (services.ntfy) domain port;
            };
            grafana = {
              inherit (services.grafana) domain port;
            };
            victoriametrics = {
              inherit (services.victoriametrics) domain port;
            };
            victorialogs = {
              inherit (services.victorialogs) domain port;
            };
            alloy = {
              inherit (services.alloy) domain port;
            };
          };
      };
  };
}
