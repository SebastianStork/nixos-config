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

    custom.networking.overlay = {
      networkAddress = "10.254.250.0";
      prefixLength = 24;
      domain = "splitleaf.de";
      interface = "nebula";
      systemdUnit = "nebula@mesh.service";
    };

    meta.ports.udp = lib.optional netCfg.underlay.isPublic publicPort;

    sops.secrets."nebula/host-key" = {
      owner = config.users.users.nebula-mesh.name;
      restartUnits = [ "nebula@mesh.service" ];
    };

    environment.etc = {
      "nebula/ca.crt" = {
        source = ./ca.crt;
        mode = "0440";
        user = config.systemd.services."nebula@mesh".serviceConfig.User;
      };
      "nebula/host.crt" = {
        source = cfg.certificatePath;
        mode = "0440";
        user = config.systemd.services."nebula@mesh".serviceConfig.User;
      };
    };

    services.nebula.networks.mesh = {
      enable = true;

      ca = "/etc/nebula/ca.crt";
      cert = "/etc/nebula/host.crt";
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
      dns = netCfg.overlay.dnsServers;
      domains = [ netCfg.overlay.domain ];
    };
  };
}
