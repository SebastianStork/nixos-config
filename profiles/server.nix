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
        domain = "alloy.${config.networking.hostName}.${config.custom.networking.overlay.domain}";
      };
    };
  };
}
