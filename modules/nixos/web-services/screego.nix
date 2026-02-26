{ config, lib, ... }:
let
  cfg = config.custom.web-services.screego;
in
{
  options.custom.web-services.screego = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5050;
    };
  };

  config = lib.mkIf cfg.enable {
    services.screego = {
      enable = true;
      openFirewall = true;
      settings = {
        SCREEGO_EXTERNAL_IP = config.custom.networking.underlay.address;
        SCREEGO_SERVER_ADDRESS = "127.0.0.1:${toString cfg.port}";
        SCREEGO_TURN_ADDRESS = "${config.custom.networking.underlay.address}:3478";
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
