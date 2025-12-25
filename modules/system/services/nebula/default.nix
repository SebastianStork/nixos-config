{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.nebula.node;

  hostname = config.networking.hostName;

  nodes =
    self.nixosConfigurations
    |> lib.filterAttrs (name: _: name != hostname)
    |> lib.attrValues
    |> lib.map (value: value.config.custom.services.nebula.node)
    |> lib.filter (node: node.enable);

  lighthouses = nodes |> lib.filter (node: node.isLighthouse);

  routableNodes = nodes |> lib.filter (node: node.routableAddress != null);
in
{
  options.custom.services.nebula.node = {
    enable = lib.mkEnableOption "";
    name = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = config.networking.hostName;
    };
    address = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    isLighthouse = lib.mkEnableOption "";

    routableAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
    };
    routablePort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = if cfg.routableAddress != null then 47141 else null;
    };

    pubPath = lib.mkOption {
      type = lib.types.path;
      default = "${self}/hosts/${hostname}/keys/nebula.pub";
    };
    certPath = lib.mkOption {
      type = lib.types.path;
      default = "${self}/hosts/${hostname}/keys/nebula.crt";
    };
  };

  config = lib.mkIf cfg.enable {
    meta.ports.udp = lib.optional (cfg.routablePort != null) cfg.routablePort;

    sops.secrets."nebula/host-key" = {
      owner = config.users.users.nebula-main.name;
      restartUnits = [ "nebula@main.service" ];
    };

    services.nebula.networks.main = {
      enable = true;

      ca = ./ca.crt;
      cert = cfg.certPath;
      key = config.sops.secrets."nebula/host-key".path;

      listen.port = cfg.routablePort;

      isLighthouse = cfg.isLighthouse;
      lighthouses = lib.mkIf (!cfg.isLighthouse) (
        lighthouses |> lib.map (lighthouse: lighthouse.address)
      );

      staticHostMap =
        routableNodes
        |> lib.map (lighthouse: {
          name = lighthouse.address;
          value = lib.singleton "${lighthouse.routableAddress}:${toString lighthouse.routablePort}";
        })
        |> lib.listToAttrs;

      firewall = {
        outbound = lib.singleton {
          host = "any";
          port = "any";
          proto = "any";
        };
        inbound = lib.singleton {
          host = "any";
          port = "any";
          proto = "any";
        };
      };

      settings = {
        pki.disconnect_invalid = true;
        cipher = "aes";
      };
    };
  };
}
