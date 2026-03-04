{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.nebula;
  netCfg = config.custom.networking;

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

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = if (netCfg.overlay.advertise.address != null) then 47141 else 0;
    };

    caCertificateFile = lib.mkOption {
      type = self.lib.types.existingPath;
      default = ./ca.crt;
    };
    publicKeyFile = lib.mkOption {
      type = self.lib.types.existingPath;
      default = "${self}/hosts/${netCfg.hostName}/keys/nebula.pub";
    };
    certificateFile = lib.mkOption {
      type = self.lib.types.existingPath;
      default = "${self}/hosts/${netCfg.hostName}/keys/nebula.crt";
    };
    privateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = netCfg.overlay.isLighthouse -> netCfg.overlay.advertise.address != null;
      message = "`${netCfg.hostName}` is a Nebula lighthouse, but `underlay.isPublic` or `overlay.advertise.address` are not set. Lighthouses must be publicly reachable.";
    };

    sops.secrets."nebula/host-key" = lib.mkIf (cfg.privateKeyFile == null) {
      owner = config.users.users.nebula-mesh.name;
      restartUnits = [ "nebula@mesh.service" ];
    };

    environment.etc = {
      "nebula/ca.crt" = {
        source = cfg.caCertificateFile;
        mode = "0440";
        user = config.systemd.services."nebula@mesh".serviceConfig.User;
      };
      "nebula/host.crt" = {
        source = cfg.certificateFile;
        mode = "0440";
        user = config.systemd.services."nebula@mesh".serviceConfig.User;
      };
    };

    services.nebula.networks.mesh = {
      enable = true;

      ca = "/etc/nebula/ca.crt";
      cert = "/etc/nebula/host.crt";
      key =
        if (cfg.privateKeyFile != null) then
          cfg.privateKeyFile
        else
          config.sops.secrets."nebula/host-key".path;

      tun.device = netCfg.overlay.interface;
      listen = {
        host = lib.mkIf (netCfg.underlay.address != null) netCfg.underlay.address;
        port = cfg.listenPort;
      };

      inherit (netCfg.overlay) isLighthouse;
      lighthouses = lib.mkIf (!netCfg.overlay.isLighthouse) lighthouses;

      isRelay = netCfg.overlay.isLighthouse;
      relays = lib.mkIf (!netCfg.overlay.isLighthouse) lighthouses;

      staticHostMap =
        netCfg.peers
        |> lib.filter (peer: peer.overlay.advertise.address != null)
        |> lib.map (peer: {
          name = peer.overlay.address;
          value = lib.singleton "${peer.overlay.advertise.address}:${toString peer.overlay.advertise.port}";
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

    systemd = {
      services."nebula@mesh" = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };

      network.networks."40-nebula" = {
        matchConfig.Name = netCfg.overlay.interface;
        address = [ netCfg.overlay.cidr ];
        dns = netCfg.overlay.dnsServers;
        domains = [ netCfg.overlay.domain ];
      };
    };
  };
}
