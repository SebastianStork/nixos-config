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
    enable = lib.mkEnableOption "" // {
      default = netCfg.overlay.implementation == "nebula";
    };

    publicKeyPath = lib.mkOption {
      type = lib.types.path;
      default = "${self}/hosts/${netCfg.hostName}/keys/nebula.pub";
    };
    certificatePath = lib.mkOption {
      type = lib.types.path;
      default = "${self}/hosts/${netCfg.hostName}/keys/nebula.crt";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = netCfg.overlay.isLighthouse -> netCfg.underlay.isPublic;
      message = "`${netCfg.hostName}` is a Nebula lighthouse, but `underlay.isPublic` is not set. Lighthouses must be publicly reachable.";
    };

    custom.networking.overlay = {
      networkCidr = "10.254.250.0/24";
      domain = "splitleaf.de";
      interface = "nebula";
      systemdUnit = "nebula@mesh.service";
    };

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

      inherit (netCfg.overlay) isLighthouse;
      lighthouses = lib.mkIf (!netCfg.overlay.isLighthouse) (
        netCfg.peers
        |> lib.filter (peer: peer.overlay.isLighthouse)
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
      address = [ netCfg.overlay.cidr ];
      dns = netCfg.overlay.dnsServers;
      domains = [ netCfg.overlay.domain ];
    };
  };
}
