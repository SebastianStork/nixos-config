{
  config,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.networking;
in
{
  options.custom.networking = {
    hostName = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = config.networking.hostName;
      readOnly = true;
    };

    nodes = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default =
        allHosts
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
      type = lib.types.listOf lib.types.attrs;
      default = cfg.nodes |> lib.filter (node: node.hostName != cfg.hostName);
      readOnly = true;
    };
  };

  config = {
    networking = {
      useNetworkd = true;
      useDHCP = false;
    };

    services.resolved.enable = true;
  };
}
