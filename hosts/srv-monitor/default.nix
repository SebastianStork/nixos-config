{ config, ... }:
{
  system.stateVersion = "25.05";

  meta = {
    domains.validate = true;
    ports.validate = true;
  };

  custom = {
    impermanence.enable = true;

    sops = {
      enable = true;
      agePublicKey = "age1zrm4vtlgv3vtq3w8jjl5zkpz7jatgscxp8mel5emzvu44s5u2uasajq8mu";
    };

    boot.loader.grub.enable = true;

    services =
      let
        tailscaleDomain = config.custom.services.tailscale.domain;
      in
      {
        resolved.enable = true;
        tailscale = {
          enable = true;
          ssh.enable = true;
        };

        gatus = {
          enable = true;
          domain = "status.${tailscaleDomain}";
          domainsToMonitor = config.meta.domains.globalList;
          endpoints = {
            "alerts" = {
              group = "Monitoring";
              path = "/v1/health";
              extraConditions = [ "[BODY].healthy == true" ];
            };
            "grafana".group = "Monitoring";
            "logs".group = "Monitoring";
            "git ssh" = {
              protocol = "ssh";
              domain = "git.sstork.dev";
            };
            "speedtest".protocol = "http";
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
            victoriametrics.enable = true;
            victorialogs.enable = true;
          };
          dashboards.node-exporter-full.enable = true;
        };

        victoriametrics = {
          enable = true;
          domain = "metrics.${tailscaleDomain}";
        };

        victorialogs = {
          enable = true;
          domain = "logs.${tailscaleDomain}";
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
          };
      };
  };
}
