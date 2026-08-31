{ self, lib, ... }:
{
  config = {
    networking = {
      domain = self.lib.privateDomain;
      hosts = lib.mkForce { };
      useNetworkd = true;
      useDHCP = false;
    };

    services.resolved.enable = true;
  };
}
