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

    networking = {
      overlay.address = "10.254.250.5";
      underlay = {
        interface = "enp1s0";
        address = "188.245.223.145";
        isPublic = true;
      };
      isLighthouse = true;
      isServer = true;
    };

    services = {
      gc = {
        enable = true;
        onlyCleanRoots = true;
      };

      nebula.enable = true;
      sshd.enable = true;
      dns.enable = true;
    };

    web-services =
      let
        privateDomain = config.custom.networking.overlay.domain;
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
          domain = "alerts.sprouted.cloud";
        };

        grafana = {
          enable = true;
          domain = "grafana.${privateDomain}";
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
