{
  config,
  inputs,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.nameservers.overlay;
  netCfg = config.custom.networking;

  zoneData = {
    SOA = {
      nameServer = "${netCfg.overlay.fqdn}.";
      adminEmail = "hostmaster@sstork.dev";
      serial = 1;
    };
    NS =
      allHosts
      |> lib.attrValues
      |> lib.filter (host: host.config.custom.services.nameservers.overlay.enable)
      |> lib.map (host: "${host.config.custom.networking.overlay.fqdn}.");

    subdomains =
      let
        mkRecord =
          { name, address }:
          {
            inherit name;
            value.A = [ address ];
          };

        nodeRecords =
          netCfg.nodes
          |> lib.map (
            node:
            mkRecord {
              name = node.hostName;
              inherit (node.overlay) address;
            }
          );
        serviceRecords =
          allHosts
          |> lib.attrValues
          |> lib.concatMap (
            host:
            host.config.custom.services.caddy.virtualHosts
            |> lib.attrValues
            |> lib.map (vHost: vHost.domain)
            |> lib.filter (domain: self.lib.isPrivateDomain domain)
            |> lib.map (
              domain:
              mkRecord {
                name = domain |> lib.removeSuffix ".${netCfg.overlay.domain}";
                inherit (host.config.custom.networking.overlay) address;
              }
            )
          );
      in
      (nodeRecords ++ serviceRecords) |> lib.listToAttrs;
  };
in
{
  options.custom.services.nameservers.overlay.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    services = {
      nsd = {
        enable = true;
        interfaces = [ netCfg.overlay.interface ];
        zones.${netCfg.overlay.domain}.data = zoneData |> inputs.dns.lib.toString netCfg.overlay.domain;
      };

      nebula.networks.mesh.firewall.inbound = lib.singleton {
        port = 53;
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
