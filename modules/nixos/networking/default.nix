{ self, lib, ... }:
{
  config = {
    networking = {
      domain = self.lib.privateDomain;
      hosts."127.0.0.2" = lib.mkForce [ ]; # Resolve the local FQDN through DNS
      useNetworkd = true;
      useDHCP = false;
    };

    services.resolved.enable = true;
  };
}
