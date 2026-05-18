{ config, lib, ... }:
let
  cfg = config.custom.web-services.homebox;
in
{
  options.custom.web-services.homebox = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 7745;
    };
  };

  config = lib.mkIf cfg.enable {
    services.homebox = {
      enable = true;
      settings = {
        HBOX_WEB_PORT = toString cfg.port;
        HBOX_WEB_HOST = "127.0.0.1";
        HBOX_OPTIONS_TRUST_PROXY = "true";
        HBOX_OPTIONS_ALLOW_REGISTRATION = "true";
      };
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      persistence.directories = lib.singleton config.services.homebox.settings.HOME;

      meta.sites.${cfg.domain} = {
        title = "HomeBox";
        icon = "sh:homebox";
      };
    };
  };
}
