{
  config,
  options,
  self,
  lib,
  ...
}:
let
  cfg = config.meta.ports;
in
{
  options.meta.ports = {
    tcp.list = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
    };
    udp.list = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
    };
    assertUnique = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.assertUnique {
    assertions =
      let
        findDuplicatePorts =
          protocol:
          options.meta.ports.${protocol}.list.definitionsWithLocations
          |> lib.concatMap (
            entry:
            entry.value
            |> lib.map (port: {
              file = entry.file |> lib.removePrefix "${self}/";
              inherit port;
            })
          )
          |> lib.groupBy (entry: builtins.toString entry.port)
          |> lib.filterAttrs (_: entries: lib.length entries > 1);

        mkErrorMessage =
          duplicatePorts:
          duplicatePorts
          |> lib.mapAttrsToList (
            port: entries:
            "Duplicate port ${port} found in:\n"
            + (entries |> lib.map (entry: "  - ${entry.file}") |> lib.concatLines)
          )
          |> lib.concatStrings;

        duplicateTcpPorts = findDuplicatePorts "tcp";

        duplicateUdpPorts = findDuplicatePorts "udp";
      in
      [
        {
          assertion = duplicateTcpPorts == { };
          message = mkErrorMessage duplicateTcpPorts;
        }
        {
          assertion = duplicateUdpPorts == { };
          message = mkErrorMessage duplicateUdpPorts;
        }
      ];
  };
}
