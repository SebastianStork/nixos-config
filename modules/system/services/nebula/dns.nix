{ config, lib, ... }:
let
  nebulaCfg = config.custom.services.nebula;
  cfg = nebulaCfg.node;
in
{
  options.custom.services.nebula.node.dns.enable = lib.mkEnableOption "";

  config = lib.mkIf (cfg.enable && cfg.dns.enable) {
    # meta.ports = {
    #   tcp = [ 53 ];
    #   udp = [ 53 ];
    # };

    services = {
      unbound = {
        enable = true;

        settings = {
          server = {
            interface = [ cfg.interface ];
            access-control = [
              "${nebulaCfg.network.address}/${toString nebulaCfg.network.prefixLength} allow"
            ];

            local-zone = "\"${nebulaCfg.network.domain}.\" static";
            local-data =
              nebulaCfg.nodes
              |> lib.map (node: "\"${node.name}.${nebulaCfg.network.domain}. A ${node.address}\"");
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
      requires = [ "nebula@mesh.service" ];
      after = [ "nebula@mesh.service" ];
    };
  };
}
