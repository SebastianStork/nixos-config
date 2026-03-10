{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.glance;

  observabilityTitles = [
    "Alloy"
    "Prometheus"
    "Alertmanager"
  ];

  hosts = allHosts |> lib.attrValues;

  applicationSites =
    hosts
    |> lib.concatMap (host: host.config.custom.meta.services |> lib.attrValues)
    |> lib.filter (service: !lib.elem service.title observabilityTitles)
    |> lib.groupBy (
      service:
      service.domain |> self.lib.isPrivateDomain |> (isPrivate: if isPrivate then "Private" else "Public")
    )
    |> lib.mapAttrsToList (
      name: value: {
        type = "monitor";
        cache = "1m";
        title = "${name} Services";
        sites = value;
      }
    )
    |> (widgets: {
      type = "split-column";
      max-columns = 2;
      inherit widgets;
    })
    |> lib.singleton;

  observabilitySites =
    hosts
    |> lib.map (host: {
      type = "monitor";
      cache = "1m";
      title = host.config.networking.hostName;
      sites =
        host.config.custom.meta.services
        |> lib.attrValues
        |> lib.filter (service: lib.elem service.title observabilityTitles);
    })
    |> lib.filter ({ sites, ... }: sites != [ ])
    |> (widgets: {
      type = "split-column";
      max-columns = widgets |> lib.length;
      inherit widgets;
    })
    |> lib.singleton;
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
              ++ applicationSites
              ++ observabilitySites;
          };
        };
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
