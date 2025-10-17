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
    validate = lib.mkEnableOption "";
  };

  config = {
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
          |> builtins.groupBy (entry: toString entry.port)
          |> lib.mapAttrs (_: values: values |> lib.map (value: value.file))
          |> lib.filterAttrs (_: files: lib.length files > 1);

        mkErrorMessage =
          duplicatePorts:
          duplicatePorts
          |> lib.mapAttrsToList (
            port: files:
            "Duplicate port `${port}` found in:\n" + (files |> lib.map (file: "  - ${file}") |> lib.concatLines)
          )
          |> lib.concatStrings;

        duplicateTcpPorts = findDuplicatePorts "tcp";
        duplicateUdpPorts = findDuplicatePorts "udp";
      in
      lib.mkIf cfg.validate [
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
