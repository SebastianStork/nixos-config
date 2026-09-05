{ config, self, ... }:
{
  imports = [ self.nixosModules.core-profile ];

  system.stateVersion = "26.05";

  custom = {
    boot.loader.systemd-boot.enable = true;
    persistence.enable = true;
    networking = {
      overlay = {
        address = "10.254.250.7";
        role = "agent";
      };
      underlay = {
        interface = "enp1s0";
        cidr = "167.235.73.246/32";
        isPublic = true;
        gateway = "172.31.1.1";
      };
    };

    services = {
      hermes-agent = {
        enable = true;
        domain = "hermes.${config.networking.domain}";
      };

      syncthing = {
        enable = true;
        inherit (config.services.hermes-agent) user group;
        dataDir = config.services.hermes-agent.stateDir;
        folders = [ "Vault" ];
      };

      auto-gc.onlyCleanRoots = true;
      deploy-webhook.enable = true;
      alloy = {
        enable = true;
        domain = "alloy.${config.networking.fqdn}";
      };
    };

    web-services.librespeed.enable = true;
  };
}
