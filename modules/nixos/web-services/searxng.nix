{ config, lib, ... }:
let
  cfg = config.custom.web-services.searxng;
in
{
  options.custom.web-services.searxng = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 27916;
    };
  };

  config = lib.mkIf cfg.enable {
    services.searx = {
      enable = true;
      settings = {
        server = {
          inherit (cfg) port;
          secret_key = "unnecessary";
        };
        ui.center_alignment = true;
        plugins = {
          "searx.plugins.calculator.SXNGPlugin".active = true;
          "searx.plugins.infinite_scroll.SXNGPlugin".active = true;
          "searx.plugins.self_info.SXNGPlugin".active = true;
        };
        search = {
          autocomplete = "duckduckgo";
          favicon_resolver = "duckduckgo";
        };
      };
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      meta.sites.${cfg.domain} = {
        title = "SearXNG";
        icon = "sh:searxng";
      };
    };
  };
}
