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
    persistence.enable = true;

    sops.enable = true;

    boot.loader.grub.enable = true;

    services = {
      tailscale.enable = true;

      nebula.node = {
        enable = true;
        address = "10.254.250.5";
        routableAddress = "188.245.223.145";
        isLighthouse = true;
        isServer = true;
        dns.enable = true;
      };
    };

    web-services =
      let
        tailscaleDomain = config.custom.services.tailscale.domain;
      in
      {
        gatus = {
          enable = true;
          domain = "status.${tailscaleDomain}";
          generateDefaultEndpoints = true;
          endpoints."alerts" = {
            path = "/v1/health";
            extraConditions = [ "[BODY].healthy == true" ];
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
      };
  };
}
