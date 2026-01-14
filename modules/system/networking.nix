{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.networking;
in
{
  options.custom.networking = {
    hostname = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = config.networking.hostName;
      readOnly = true;
    };
    isLighthouse = lib.mkEnableOption "";
    isServer = lib.mkEnableOption "";
    isClient = lib.mkEnableOption "";

    overlay = {
      networkAddress = lib.mkOption {
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

      address = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "";
      };
      interface = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "nebula";
      };
      systemdUnit = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "nebula@mesh.service";
      };

      dnsServers = lib.mkOption {
        type = lib.types.anything;
        default =
          self.nixosConfigurations
          |> lib.attrValues
          |> lib.filter (host: host.config.custom.services.dns.enable)
          |> lib.map (host: host.config.custom.networking.overlay.address);
      };
    };

    underlay = {
      interface = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "";
      };
      useDhcp = lib.mkEnableOption "";
      isPublic = lib.mkEnableOption "";
      address = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = null;
      };
      gateway = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = null;
      };
    };

    nodes = lib.mkOption {
      type = lib.types.anything;
      default =
        self.nixosConfigurations
        |> lib.attrValues
        |> lib.map (host: host.config.custom.networking)
        |> lib.map (
          node:
          lib.removeAttrs node [
            "nodes"
            "peers"
          ]
        );
      readOnly = true;
    };
    peers = lib.mkOption {
      type = lib.types.anything;
      default = cfg.nodes |> lib.filter (node: node.hostname != cfg.hostname);
      readOnly = true;
    };
  };
}
