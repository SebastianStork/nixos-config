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

      caddy.virtualHosts."alerts.sprouted.cloud" = {
        inherit (config.custom.web-services.ntfy) port;
        extraConfig = ''
          @putpost method PUT POST
          respond @putpost "Access denied" 403 { close }
        '';
      };
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
          endpoints."alerts.${privateDomain}" = {
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
