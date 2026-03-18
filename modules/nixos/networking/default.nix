{ config, lib, ... }:
{
  options.custom.networking.hostName = lib.mkOption {
    type = lib.types.nonEmptyStr;
    default = config.networking.hostName;
    readOnly = true;
  };

  config = {
    networking = {
      useNetworkd = true;
      useDHCP = false;
    };

    services.resolved.enable = true;
  };
}
