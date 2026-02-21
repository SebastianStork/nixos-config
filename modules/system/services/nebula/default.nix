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

  lighthouses =
    netCfg.peers
    |> lib.filter (peer: peer.overlay.isLighthouse)
    |> lib.map (lighthouse: lighthouse.overlay.address);
in
{
  options.custom.services.nebula = {
    enable = lib.mkEnableOption "" // {
      default = netCfg.overlay.implementation == "nebula";
    };
    groups = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.nonEmptyStr;
      default =
        lib.singleton netCfg.overlay.role
        ++ lib.optional config.custom.services.syncthing.enable "syncthing";
    };

    caCertificatePath = lib.mkOption {
      type = lib.types.path;
      default = ./ca.crt;
    };
    publicKeyPath = lib.mkOption {
      type = lib.types.path;
      default = "${self}/hosts/${netCfg.hostName}/keys/nebula.pub";
    };
    certificatePath = lib.mkOption {
      type = lib.types.path;
      default = "${self}/hosts/${netCfg.hostName}/keys/nebula.crt";
    };
    privateKeyPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = netCfg.overlay.isLighthouse -> netCfg.underlay.isPublic;
      message = "`${netCfg.hostName}` is a Nebula lighthouse, but `underlay.isPublic` is not set. Lighthouses must be publicly reachable.";
    };

    sops.secrets."nebula/host-key" = lib.mkIf (cfg.privateKeyPath == null) {
      owner = config.users.users.nebula-mesh.name;
      restartUnits = [ "nebula@mesh.service" ];
    };

    environment.etc = {
      "nebula/ca.crt" = {
        source = cfg.caCertificatePath;
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
      key =
        if (cfg.privateKeyPath != null) then
          cfg.privateKeyPath
        else
          config.sops.secrets."nebula/host-key".path;

      tun.device = netCfg.overlay.interface;
      listen = {
        host = lib.mkIf (netCfg.underlay.address != null) netCfg.underlay.address;
        port = lib.mkIf netCfg.underlay.isPublic publicPort;
      };

      inherit (netCfg.overlay) isLighthouse;
      lighthouses = lib.mkIf (!netCfg.overlay.isLighthouse) lighthouses;

      isRelay = netCfg.overlay.isLighthouse;
      relays = lib.mkIf (!netCfg.overlay.isLighthouse) lighthouses;

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
