{ config, self, ... }:
{
  imports = [ self.nixosModules.profile-core ];

  custom = {
    persistence.enable = true;
    networking.overlay.role = "server";
    services = {
      auto-gc.onlyCleanRoots = true;
      comin.enable = true;
    };
    web-services.alloy = {
      enable = true;
      domain = "alloy.${config.networking.hostName}.${config.custom.networking.overlay.domain}";
    };
  };
}
