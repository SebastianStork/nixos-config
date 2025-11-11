{ config, lib, ... }:
let
  cfg = config.custom.services.openspeedtest;
in
{
  options.custom.services.openspeedtest = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 4479;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.local = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    virtualisation.oci-containers.containers.openspeedtest = {
      image = "openspeedtest/latest";
      ports = [ "127.0.0.1:${toString cfg.port}:3000" ];
      pull = "newer";
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
