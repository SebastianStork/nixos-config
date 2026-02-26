{ config, lib, ... }:
let
  cfg = config.custom.web-services.privatebin;
in
{
  options.custom.web-services.privatebin = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 61009;
    };
    branding.name = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "PrivateBin";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      privatebin = {
        enable = true;
        enableNginx = true;
        virtualHost = "privatebin";
        settings.main = {
          basepath = "https://${cfg.domain}";
          inherit (cfg.branding) name;
        };
      };

      nginx.virtualHosts.privatebin.listen = lib.singleton {
        addr = "localhost";
        inherit (cfg) port;
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
