{ config, self, ... }:
{
  imports = [ self.nixosModules.core-profile ];

  custom = {
    persistence.enable = true;
    networking.overlay.role = "server";
    services = {
      auto-gc.onlyCleanRoots = true;
      comin.enable = true;
      alloy = {
        enable = true;
        domain = "alloy.${config.custom.networking.overlay.fqdn}";
      };
      prometheus = {
        enable = true;
        domain = "prometheus.${config.custom.networking.overlay.fqdn}";
      };
      alertmanager = {
        enable = true;
        domain = "alertmanager.${config.custom.networking.overlay.fqdn}";
      };
    };
  };
}
