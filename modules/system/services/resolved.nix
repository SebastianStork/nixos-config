{ config, lib, ... }:
let
  ports = [
    53
    5353
    5355
  ];
in
{
  options.custom.services.resolved.enable = lib.mkEnableOption "" // {
    default = config.systemd.network.enable;
  };

  config = lib.mkIf config.custom.services.resolved.enable {
    meta.ports = {
      tcp = ports;
      udp = ports;
    };

    services.resolved = {
      enable = true;
      dnssec = "allow-downgrade";
      dnsovertls = "opportunistic";
    };
  };
}
