{ config, self, ... }:
{
  imports = [ self.nixosModules.core-profile ];

  custom = {
    persistence.enable = true;
    networking.overlay.role = "server";
    services = {
      auto-gc.onlyCleanRoots = true;
      deploy-webhook.enable = true;
      alloy = {
        enable = true;
        domain = "alloy.${config.networking.fqdn}";
      };
      prometheus = {
        enable = true;
        domain = "prometheus.${config.networking.fqdn}";
      };
      alertmanager = {
        enable = true;
        domain = "alertmanager.${config.networking.fqdn}";
      };
    };
    web-services.librespeed.enable = true;
  };
}
