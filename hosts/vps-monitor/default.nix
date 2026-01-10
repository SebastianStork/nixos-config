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
      gc = {
        enable = true;
        onlyCleanRoots = true;
      };

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
        privateDomain = config.custom.services.nebula.network.domain;
      in
      {
        gatus = {
          enable = true;
          domain = "status.${privateDomain}";
          generateDefaultEndpoints = true;
          endpoints."alerts" = {
            path = "/v1/health";
            extraConditions = [ "[BODY].healthy == true" ];
          };
        };

        ntfy = {
          enable = true;
          domain = "alerts.${privateDomain}";
        };

        grafana = {
          enable = true;
          domain = "grafana.${privateDomain}";
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
          domain = "metrics.${privateDomain}";
        };

        victorialogs = {
          enable = true;
          domain = "logs.${privateDomain}";
        };

        alloy = {
          enable = true;
          domain = "alloy.${config.networking.hostName}.${privateDomain}";
        };
      };
  };
}
