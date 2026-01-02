{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.nebula.node;
  peers = config.custom.services.nebula.peers;

  hostname = config.networking.hostName;

  lighthouses = peers |> lib.filter (node: node.isLighthouse);

  routablePeers = peers |> lib.filter (node: node.routableAddress != null);
in
{
  options.custom.services.nebula = {
    node = {
      enable = lib.mkEnableOption "";
      name = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = hostname;
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

    peers = lib.mkOption {
      type = lib.types.anything;
      default =
        self.nixosConfigurations
        |> lib.filterAttrs (name: _: name != hostname)
        |> lib.attrValues
        |> lib.map (value: value.config.custom.services.nebula.node)
        |> lib.filter (node: node.enable);
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

      isLighthouse = cfg.isLighthouse;
      lighthouses = lib.mkIf (!cfg.isLighthouse) (
        lighthouses |> lib.map (lighthouse: lighthouse.address)
      );

      staticHostMap =
        routablePeers
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
        logging.level = "warning";
      };
    };

    networking.firewall.trustedInterfaces = [ "nebula.mesh" ];
  };
}
