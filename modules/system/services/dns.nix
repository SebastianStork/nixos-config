{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.dns;
  netCfg = config.custom.networking;
in
{
  options.custom.services.dns.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    services = {
      unbound = {
        enable = true;

        settings.server = {
          interface = [ netCfg.overlay.interface ];
          access-control = [ "${toString netCfg.overlay.networkCidr} allow" ];

          local-zone = "\"${netCfg.overlay.domain}.\" static";
          local-data =
            let
              nodeRecords =
                netCfg.nodes
                |> lib.map (node: "\"${node.hostName}.${node.overlay.domain}. A ${node.overlay.address}\"");
              serviceRecords =
                allHosts
                |> lib.attrValues
                |> lib.concatMap (
                  host:
                  host.config.custom.services.caddy.virtualHosts
                  |> lib.attrValues
                  |> lib.map (vHost: vHost.domain)
                  |> lib.filter (domain: self.lib.isPrivateDomain domain)
                  |> lib.map (domain: "\"${domain}. A ${host.config.custom.networking.overlay.address}\"")
                );
            in
            nodeRecords ++ serviceRecords;
        };
      };

      nebula.networks.mesh.firewall.inbound = lib.singleton {
        port = 53;
        proto = "any";
        host = "any";
      };
    };

    systemd.services.unbound = {
      requires = [ netCfg.overlay.systemdUnit ];
      after = [ netCfg.overlay.systemdUnit ];
    };
  };
}
