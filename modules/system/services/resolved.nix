{ config, lib, ... }:
{
  options.custom.services.resolved.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.resolved.enable {
    meta.ports.list = [
      53
      5353
      5355
    ];

    services.resolved.enable = true;
  };
}
