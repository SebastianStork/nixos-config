{
  config,
  inputs,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.private-nameserver;
  netCfg = config.custom.networking;

  zoneData = inputs.dns.lib.toString netCfg.overlay.domain {
    SOA = {
      nameServer = "${netCfg.overlay.fqdn}.";
      adminEmail = "hostmaster@sstork.dev";
      serial = 1;
    };

    NS =
      allHosts
      |> lib.attrValues
      |> lib.filter (host: host.config.custom.services.private-nameserver.enable)
      |> lib.map (host: "${host.config.custom.networking.overlay.fqdn}.");

    subdomains =
      let
        mkSubdomain =
          { name, address }:
          {
            inherit name;
            value.A = [ address ];
          };

        nodeRecords =
          netCfg.nodes
          |> lib.map (node: {
            name = node.hostName;
            inherit (node.overlay) address;
          });

        serviceRecords =
          allHosts
          |> lib.attrValues
          |> lib.concatMap (
            host:
            host.config.custom.services.caddy.virtualHosts
            |> lib.attrValues
            |> lib.map (vHost: vHost.domain)
            |> lib.filter (domain: self.lib.isPrivateDomain domain)
            |> lib.map (domain: {
              name = domain |> lib.removeSuffix ".${netCfg.overlay.domain}";
              inherit (host.config.custom.networking.overlay) address;
            })
          );
      in
      (nodeRecords ++ serviceRecords) |> lib.map mkSubdomain |> lib.listToAttrs;
  };
in
{
  options.custom.services.private-nameserver = {
    enable = lib.mkEnableOption "";
    port = lib.mkOption {
      type = lib.types.port;
      default = 5335;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      nsd = {
        enable = true;
        interfaces = [ "${netCfg.overlay.address}@${toString cfg.port}" ];
        zones.${netCfg.overlay.domain}.data = zoneData;
      };

      nebula.networks.mesh.firewall.inbound = lib.singleton {
        inherit (cfg) port;
        proto = "any";
        host = "any";
      };
    };

    systemd.services.nsd = {
      requires = [ netCfg.overlay.systemdUnit ];
      after = [ netCfg.overlay.systemdUnit ];
    };
  };
}
