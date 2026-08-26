{ self, ... }:
{
  config = {
    networking = {
      domain = self.lib.privateDomain;
      useNetworkd = true;
      useDHCP = false;
    };

    services.resolved.enable = true;
  };
}
