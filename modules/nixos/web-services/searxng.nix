{
  config,
  self,
  pkgs-unstable,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.searxng;
  hermesHosts =
    allHosts
    |> lib.attrValues
    |> lib.filter (host: host.config.custom.services.hermes-agent.enable)
    |> lib.map (host: host.config.networking.hostName);
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
    api.allowHermes = lib.mkEnableOption "";
    forwardAuth = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = self.lib.isPrivateDomain cfg.domain || cfg.forwardAuth;
      message = self.lib.mkUnprotectedMessage "SearXNG";
    };

    services.searx = {
      enable = true;
      package = pkgs-unstable.searxng;
      settings = {
        server = {
          inherit (cfg) port;
          bind_address = if cfg.api.allowHermes then "0.0.0.0" else "127.0.0.1";
          secret_key = "unnecessary";
        };
        ui.center_alignment = true;
        plugins = {
          "searx.plugins.calculator.SXNGPlugin".active = true;
          "searx.plugins.infinite_scroll.SXNGPlugin".active = true;
          "searx.plugins.self_info.SXNGPlugin".active = true;
          "searx.plugins.hostnames.SXNGPlugin".active = true;
        };
        search = {
          autocomplete = "duckduckgo";
          favicon_resolver = "duckduckgo";
          formats = [ "html" ] ++ lib.optional cfg.api.allowHermes "json";
        };
        hostnames = {
          remove = [ "(.*\.)?nixos.wiki$" ];
          high_priority = [
            "(.*\.)?github.com$"
            "(.*\.)?nixos.org$"
            "(.*\.)archlinux.org$"
            "(.*\.)?reddit.com$"
          ];
        };
      };
    };

    services.nebula.networks.mesh.firewall.inbound = lib.mkIf cfg.api.allowHermes (
      hermesHosts
      |> lib.map (host: {
        inherit (cfg) port;
        proto = "tcp";
        inherit host;
      })
    );

    custom = {
      services.caddy.virtualHosts.${cfg.domain} = {
        inherit (cfg) port;
        forwardAuth = {
          enable = cfg.forwardAuth;
          bypassPaths = [ "/healthz" ];
        };
      };

      meta.sites.${cfg.domain} = {
        title = "SearXNG";
        icon = "searxng";
        checkPath = "/healthz";
      };
    };
  };
}
