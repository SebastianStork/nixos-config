{ config, lib, ... }:
{
  options.custom.services.resolved.enable = lib.mkEnableOption "" // {
    default = config.systemd.network.enable;
  };

  config = lib.mkIf config.custom.services.resolved.enable {
    services.resolved = {
      enable = true;
      dnssec = "allow-downgrade";
      dnsovertls = "opportunistic";
    };
  };
}
