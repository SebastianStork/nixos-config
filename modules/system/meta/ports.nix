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
    tcp = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
    };
    udp = lib.mkOption {
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
          options.meta.ports.${protocol}.definitionsWithLocations
          |> lib.concatMap (
            { file, value }:
            value
            |> lib.map (port: {
              file = self.lib.relativePath file;
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
