{
  config,
  self,
  lib,
  ...
}:
let
  nebulaCfg = config.custom.services.nebula;
  cfg = nebulaCfg.node;

  hostname = config.networking.hostName;
in
{
  options.custom.services.nebula = {
    network = {
      address = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "10.254.250.0";
        readOnly = true;
      };
      prefixLength = lib.mkOption {
        type = lib.types.ints.between 0 32;
        default = 24;
        readOnly = true;
      };
      domain = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "splitleaf.de";
        readOnly = true;
      };
    };

    node = {
      enable = lib.mkEnableOption "";
      name = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = hostname;
      };
      interface = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "nebula.mesh";
      };
      address = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "";
      };
      isLighthouse = lib.mkEnableOption "";
      isServer = lib.mkEnableOption "";
      isClient = lib.mkEnableOption "";

      routableAddress = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = null;
      };
      routablePort = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = if cfg.routableAddress != null then 47141 else null;
      };

      publicKeyPath = lib.mkOption {
        type = lib.types.path;
        default = "${self}/hosts/${hostname}/keys/nebula.pub";
      };
      certificatePath = lib.mkOption {
        type = lib.types.path;
        default = "${self}/hosts/${hostname}/keys/nebula.crt";
      };
    };

    nodes = lib.mkOption {
      type = lib.types.anything;
      default =
        self.nixosConfigurations
        |> lib.attrValues
        |> lib.map (value: value.config.custom.services.nebula.node)
        |> lib.filter (node: node.enable);
      readOnly = true;
    };
    peers = lib.mkOption {
      type = lib.types.anything;
      default = nebulaCfg.nodes |> lib.filter (node: node.name != hostname);
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable {
    meta.ports.udp = lib.optional (cfg.routablePort != null) cfg.routablePort;

    assertions = lib.singleton {
      assertion = cfg.isLighthouse -> cfg.routableAddress != null;
      message = "'${hostname}' is a Nebula lighthouse, but routableAddress is not set. Lighthouses must be publicly reachable.";
    };

    sops.secrets."nebula/host-key" = {
      owner = config.users.users.nebula-mesh.name;
      restartUnits = [ "nebula@mesh.service" ];
    };

    services.nebula.networks.mesh = {
      enable = true;

      ca = ./ca.crt;
      cert = cfg.certificatePath;
      key = config.sops.secrets."nebula/host-key".path;

      listen.port = cfg.routablePort;

      inherit (cfg) isLighthouse;
      lighthouses = lib.mkIf (!cfg.isLighthouse) (
        nebulaCfg.peers |> lib.filter (node: node.isLighthouse) |> lib.map (lighthouse: lighthouse.address)
      );

      staticHostMap =
        nebulaCfg.peers
        |> lib.filter (node: node.routableAddress != null)
        |> lib.map (lighthouse: {
          name = lighthouse.address;
          value = lib.singleton "${lighthouse.routableAddress}:${toString lighthouse.routablePort}";
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

    networking.firewall.trustedInterfaces = [ cfg.interface ];

    systemd.network.networks."40-nebula" = {
      matchConfig.Name = cfg.interface;
      address = [ "${cfg.address}/${toString nebulaCfg.network.prefixLength}" ];
      dns = nebulaCfg.peers |> lib.filter (node: node.dns.enable) |> lib.map (node: node.address);
      domains = [ nebulaCfg.network.domain ];
    };
  };
}
