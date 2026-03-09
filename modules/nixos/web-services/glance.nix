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
        inherit (cfg) port;

        pages = lib.singleton {
          name = "Services";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "monitor";
                  cache = "1m";
                  title = "Services";
                  sites =
                    allHosts
                    |> lib.attrValues
                    |> lib.map (
                      host:
                      host.config.custom.services.caddy.virtualHosts |> lib.attrValues |> lib.map (vHost: vHost.domain)
                    )
                    |> lib.concatLists
                    |> lib.map (domain: {
                      title = domain;
                      url = domain;
                    });
                }
              ];
            }
          ];
        };
      };
    };

    custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
  };
}
