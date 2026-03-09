{
  config,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.glance;

  servicesWidgets =
    allHosts
    |> lib.attrValues
    |> lib.map (host: {
      hostName = host.config.networking.hostName;
      services = host.config.custom.meta.services |> lib.attrValues;
    })
    |> lib.filter ({ services, ... }: services != [ ])
    |> lib.map (
      { hostName, services }:
      {
        type = "monitor";
        cache = "1m";
        title = "Services - ${hostName}";
        sites = services;
      }
    );
in
{
  options.custom.web-services.glance = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 63958;
    };
  };

  config = lib.mkIf cfg.enable {
    services.glance = {
      enable = true;

      settings = {
        server.port = cfg.port;

        pages = lib.singleton {
          name = "Home";
          center-vertically = true;

          columns = lib.singleton {
            size = "full";
            widgets =
              lib.singleton {
                type = "search";
                search-engine = "google";
                autofocus = true;
              }
              ++ servicesWidgets;
          };
        };
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
