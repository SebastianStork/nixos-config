{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.nebula;
  netCfg = config.custom.networking;

  publicPort = 47141;
in
{
  options.custom.services.nebula = {
    enable = lib.mkEnableOption "";

    publicKeyPath = lib.mkOption {
      type = lib.types.path;
      default = "${self}/hosts/${netCfg.hostname}/keys/nebula.pub";
    };
    certificatePath = lib.mkOption {
      type = lib.types.path;
      default = "${self}/hosts/${netCfg.hostname}/keys/nebula.crt";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = netCfg.isLighthouse -> netCfg.underlay.isPublic;
      message = "'${netCfg.hostname}' is a Nebula lighthouse, but underlay.isPublic is not set. Lighthouses must be publicly reachable.";
    };

    meta.ports.udp = lib.optional netCfg.underlay.isPublic publicPort;

    sops.secrets."nebula/host-key" = {
      owner = config.users.users.nebula-mesh.name;
      restartUnits = [ "nebula@mesh.service" ];
    };

    services.nebula.networks.mesh = {
      enable = true;

      ca = ./ca.crt;
      cert = cfg.certificatePath;
      key = config.sops.secrets."nebula/host-key".path;

      tun.device = netCfg.overlay.interface;
      listen.port = lib.mkIf netCfg.underlay.isPublic publicPort;

      inherit (netCfg) isLighthouse;
      lighthouses = lib.mkIf (!netCfg.isLighthouse) (
        netCfg.peers
        |> lib.filter (peer: peer.isLighthouse)
        |> lib.map (lighthouse: lighthouse.overlay.address)
      );

      staticHostMap =
        netCfg.peers
        |> lib.filter (peer: peer.underlay.isPublic)
        |> lib.map (publicPeer: {
          name = publicPeer.overlay.address;
          value = lib.singleton "${publicPeer.underlay.address}:${toString publicPort}";
        })
        |> lib.listToAttrs;

      firewall = {
        outbound = lib.singleton {
          port = "any";
          proto = "any";
          host = "any";
        };
        inbound = lib.singleton {
          port = "any";
          proto = "icmp";
          host = "any";
        };
      };

      settings = {
        pki.disconnect_invalid = true;
        cipher = "aes";
      };
    };

    networking.firewall.trustedInterfaces = [ netCfg.overlay.interface ];

    systemd.network.networks."40-nebula" = {
      matchConfig.Name = netCfg.overlay.interface;
      address = [ "${netCfg.overlay.address}/${toString netCfg.overlay.prefixLength}" ];
      dns =
        self.nixosConfigurations
        |> lib.attrValues
        |> lib.filter (host: host.config.custom.services.dns.enable)
        |> lib.map (host: host.config.custom.networking.overlay.address);
      domains = [ netCfg.overlay.domain ];
    };
  };
}
