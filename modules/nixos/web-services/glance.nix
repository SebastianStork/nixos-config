{
  config,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.glance;
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
          name = "Services";
          columns = lib.singleton {
            size = "full";
            widgets =
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
