{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  netCfg = config.custom.networking;
  cfg = netCfg.overlay.nebula;

  lighthouses =
    allHosts
    |> lib.attrValues
    |> lib.filter (host: host.config.networking.hostName != config.networking.hostName)
    |> lib.filter (host: host.config.custom.networking.overlay.enable)
    |> lib.filter (host: host.config.custom.networking.overlay.isLighthouse)
    |> lib.map (host: host.config.custom.networking.overlay.address);
in
{
  options.custom.networking.overlay.nebula = {
    listenPort = lib.mkOption {
      type = lib.types.port;
      default = if (cfg.advertise.address != null) then 47141 else 0;
    };
    advertise = {
      address = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = if netCfg.underlay.isPublic then netCfg.underlay.address else null;
      };
      port = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = if cfg.advertise.address != null then cfg.listenPort else null;
      };
    };

    caCertificateFile = lib.mkOption {
      type = self.lib.types.existingPath;
      default = ./nebula-ca.crt;
    };
    publicKeyFile = lib.mkOption {
      type = self.lib.types.existingPath;
      default = "${self}/hosts/nixos/${config.networking.hostName}/keys/nebula.pub";
    };
    certificateFile = lib.mkOption {
      type = self.lib.types.existingPath;
      default = "${self}/hosts/nixos/${config.networking.hostName}/keys/nebula.crt";
    };
    privateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    unsafeNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = lib.optional netCfg.overlay.isExitNode "0.0.0.0/0";
    };
  };

  config = lib.mkIf netCfg.overlay.enable {
    assertions = lib.singleton {
      assertion = netCfg.overlay.isLighthouse -> cfg.advertise.address != null;
      message = self.lib.mkInvalidConfigMessage "Nebula lighthouse `${config.networking.hostName}`" "`underlay.isPublic` must be enabled or `overlay.nebula.advertise.address` must be set so the host is publicly reachable";
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
        source = self.lib.isolateStorePath cfg.certificateFile;
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
        allHosts
        |> lib.attrValues
        |> lib.filter (host: host.config.custom.networking.overlay.enable)
        |> lib.filter (host: host.config.custom.networking.overlay.nebula.advertise.address != null)
        |> self.lib.genAttrs' (host: {
          name = host.config.custom.networking.overlay.address;
          value = lib.singleton "${host.config.custom.networking.overlay.nebula.advertise.address}:${lib.toString host.config.custom.networking.overlay.nebula.advertise.port}";
        });

      firewall = {
        outbound = lib.singleton {
          port = "any";
          proto = "any";
          host = "any";
        };
        inbound =
          lib.singleton {
            port = "any";
            proto = "icmp";
            host = "any";
          }
          ++ lib.optional netCfg.overlay.isExitNode {
            port = "any";
            proto = "any";
            group = "client";
          };
      };

      settings = {
        pki.disconnect_invalid = true;
        cipher = "aes";
      };
    };

    networking = {
      firewall.trustedInterfaces = [ netCfg.overlay.interface ];
      nat = lib.mkIf netCfg.overlay.isExitNode {
        enable = true;
        externalInterface = netCfg.underlay.interface;
        internalInterfaces = [ netCfg.overlay.interface ];
      };
    };

    systemd = {
      services."nebula@mesh" = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };

      network.networks."40-nebula" = {
        matchConfig.Name = netCfg.overlay.interface;
        address = [ netCfg.overlay.cidr ];
        dns = netCfg.overlay.dnsServers;
        domains = [ config.networking.domain ];
      };
    };
  };
}
