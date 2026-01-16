{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.dns;
  netCfg = config.custom.networking;
in
{
  options.custom.services.dns.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    # meta.ports = {
    #   tcp = [ 53 ];
    #   udp = [ 53 ];
    # };

    services = {
      unbound = {
        enable = true;

        settings = {
          server = {
            interface = [ netCfg.overlay.interface ];
            access-control = [
              "${netCfg.overlay.networkAddress}/${toString netCfg.overlay.prefixLength} allow"
            ];

            local-zone = "\"${netCfg.overlay.domain}.\" static";
            local-data =
              let
                nodeRecords =
                  netCfg.nodes
                  |> lib.map (node: "\"${node.hostname}.${node.overlay.domain}. A ${node.overlay.address}\"");
                serviceRecords =
                  self.nixosConfigurations
                  |> lib.attrValues
                  |> lib.concatMap (
                    host:
                    host.config.meta.domains.local
                    |> lib.filter (domain: self.lib.isPrivateDomain domain)
                    |> lib.map (domain: "\"${domain}. A ${host.config.custom.networking.overlay.address}\"")
                  );
              in
              nodeRecords ++ serviceRecords;
          };

          forward-zone = lib.singleton {
            name = ".";
            forward-addr = [
              "1.1.1.1"
              "8.8.8.8"
            ];
          };
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
