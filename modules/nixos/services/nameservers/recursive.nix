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

  hosts = allHosts |> lib.attrValues;

  onSameLan =
    host:
    let
      underlay = host.config.custom.networking.underlay;
    in
    underlay.trusted && underlay.cidr == netCfg.underlay.cidr;

  mkLocalData =
    targetHosts: getAddress:
    let
      nodeRecords =
        targetHosts
        |> lib.map (
          host: ''"${host.config.custom.networking.hostName}.${netCfg.overlay.domain}. A ${getAddress host}"''
        );

      serviceRecords =
        targetHosts
        |> lib.concatMap (
          host:
          host.config.custom.services.caddy.virtualHosts
          |> lib.attrValues
          |> lib.filter (vHost: self.lib.isPrivateDomain vHost.domain)
          |> lib.map (vHost: ''"${vHost.domain}. A ${getAddress host}"'')
        );
    in
    nodeRecords ++ serviceRecords;
in
{
  options.custom.services.recursive-nameserver = {
    enable = lib.mkEnableOption "";
    serveAuthoritatively = lib.mkEnableOption "";
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
              interface = [ "${netCfg.overlay.address}@${lib.toString cfg.port}" ];
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

      (lib.mkIf cfg.serveAuthoritatively {
        services.unbound.settings = {
          server = {
            access-control-view = [ "${netCfg.overlay.networkCidr} overlay" ];
            local-zone = ''"${netCfg.overlay.domain}." static'';
          };

          view = lib.singleton {
            name = "overlay";
            local-zone = ''"${netCfg.overlay.domain}." static'';
            local-data = mkLocalData hosts (host: host.config.custom.networking.overlay.address);
          };
        };
      })

      (lib.mkIf (cfg.serveAuthoritatively && netCfg.underlay.trusted) {
        services.unbound.settings = {
          server = {
            interface = [ "127.0.0.1@${lib.toString cfg.port}" ];
            access-control = [ "127.0.0.1/32 allow" ];
            access-control-view = [ "127.0.0.1/32 lan" ];
          };
          view = lib.singleton {
            name = "lan";
            local-zone = ''"${netCfg.overlay.domain}." static'';
            local-data = mkLocalData (hosts |> lib.filter onSameLan) (
              host: host.config.custom.networking.underlay.address
            );
          };
        };
      })
    ]
  );
}
