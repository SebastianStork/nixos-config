{ config, lib, ... }:
let
  cfg = config.custom.web-services.networking-toolbox;
in
{
  options.custom.web-services.networking-toolbox = {
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
    virtualisation.oci-containers.containers.networking-toolbox = {
      image = "lissy93/networking-toolbox";
      ports = [ "127.0.0.1:${toString cfg.port}:3000" ];
      pull = "newer";
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
