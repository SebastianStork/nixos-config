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
        sites =
          services
          |> lib.map (
            {
              name,
              url,
              icon,
            }:
            {
              title = name;
              inherit url icon;
            }
          );
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
          hide-desktop-navigation = true;
          columns = lib.singleton {
            size = "full";
            widgets = [
              {
                type = "search";
                search-engine = "google";
                autofocus = true;
              }
              {
                type = "split-column";
                widgets = servicesWidgets;
              }
            ];
          };
        };
      };
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      meta.services.${cfg.domain} = {
        name = "Glance";
        icon = "sh:glance";
      };
    };
  };
}
