{
  config,
  lib,
  self,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.recursive-nameserver;
  netCfg = config.custom.networking;

  privateNameservers =
    allHosts
    |> lib.attrValues
    |> lib.filter (host: host.config.custom.services.private-nameserver.enable)
    |> lib.map (
      host:
      "${host.config.custom.networking.overlay.address}@${toString host.config.custom.services.private-nameserver.port}"
    );

  lanLocalData =
    allHosts
    |> lib.attrValues
    |> lib.filter (host: host.config.custom.networking.underlay.trusted)
    |> lib.filter (host: host.config.custom.networking.underlay.cidr == netCfg.underlay.cidr)
    |> lib.concatMap (
      host:
      host.config.custom.services.caddy.virtualHosts
      |> lib.attrValues
      |> lib.filter (vHost: self.lib.isPrivateDomain vHost.domain)
      |> lib.map (vHost: ''"${vHost.domain}. A ${host.config.custom.networking.underlay.address}"'')
    );
in
{
  options.custom.services.recursive-nameserver = {
    enable = lib.mkEnableOption "";
    port = lib.mkOption {
      type = lib.types.port;
      default = 5336;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services = {
          unbound = {
            enable = true;
            settings.server = {
              interface = [ "${netCfg.overlay.address}@${toString cfg.port}" ];
              access-control = [ "${netCfg.overlay.networkCidr} allow" ];
              prefetch = true;
            };
          };

          nebula.networks.mesh.firewall.inbound = lib.singleton {
            inherit (cfg) port;
            proto = "any";
            host = "any";
          };
        };

        systemd.services.unbound = {
          requires = [ netCfg.overlay.systemdUnit ];
          after = [ netCfg.overlay.systemdUnit ];
        };
      }

      (lib.mkIf (privateNameservers != [ ]) {
        services.unbound.settings = {
          server = {
            local-zone = ''"${netCfg.overlay.domain}." nodefault'';
            domain-insecure = netCfg.overlay.domain;
          };

          stub-zone = lib.singleton {
            name = netCfg.overlay.domain;
            stub-addr = privateNameservers;
          };
        };
      })

      (lib.mkIf netCfg.underlay.trusted {
        services.unbound.settings = {
          server = {
            interface = [ "127.0.0.1@${toString cfg.port}" ];
            access-control = [ "127.0.0.1/32 allow" ];
            access-control-view = "127.0.0.1/32 lan";
          };
          view = [
            {
              name = "lan";
              local-zone = ''"${netCfg.overlay.domain}." static'';
              local-data = lanLocalData;
            }
          ];
        };
      })
    ]
  );
}
