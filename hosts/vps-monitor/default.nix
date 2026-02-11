{ config, self, ... }:
{
  imports = [ self.nixosModules.server-profile ];

  system.stateVersion = "25.11";

  custom = {
    boot.loader.grub.enable = true;

    networking = {
      overlay = {
        address = "10.254.250.5";
        isLighthouse = true;
      };
      underlay = {
        interface = "enp1s0";
        cidr = "188.245.223.145/32";
        isPublic = true;
        gateway = "172.31.1.1";
      };
    };

    services.dns.enable = true;

    web-services =
      let
        privateDomain = config.custom.networking.overlay.domain;
        sproutedDomain = "sprouted.cloud";
      in
      {
        gatus = {
          enable = true;
          domain = "status.${privateDomain}";
          generateDefaultEndpoints = true;
          endpoints = {
            "dav.${sproutedDomain}".enable = false;
            "alerts.${sproutedDomain}" = {
              path = "/v1/health";
              extraConditions = [ "[BODY].healthy == true" ];
            };
          };
        };

        ntfy = {
          enable = true;
          domain = "alerts.${sproutedDomain}";
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
      };
  };
}
