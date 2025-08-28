{ config, lib, ... }:
{
  options.custom.services.resolved.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.resolved.enable {
    meta.ports =
      let
        ports = [
          53
          5353
          5355
        ];
      in
      {
        tcp.list = ports;
        udp.list = ports;
      };

    services.resolved.enable = true;
  };
}
