{ config, lib, ... }:
let
  cfg = config.custom.services.stirling-pdf;
in
{
  options.custom.services.stirling-pdf = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 56191;
    };
    branding = {
      name = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "Stirling PDF";
      };
      description = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "Your locally hosted one-stop-shop for all your PDF needs.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.local = [ cfg.domain ];
      ports.tcp = [ cfg.port ];
    };

    services.stirling-pdf = {
      enable = true;
      environment = {
        SERVER_ADDRESS = "127.0.0.1";
        SERVER_PORT = cfg.port;
        SYSTEM_ENABLEANALYTICS = "false";
        LANGS = "de_DE";

        UI_APPNAME = cfg.branding.name;
        UI_APPNAVBARNAME = cfg.branding.name;
        UI_HOMEDESCRIPTION = cfg.branding.description;
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
