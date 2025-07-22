{
  config,
  options,
  lib,
  ...
}:
let
  cfg = config.meta.ports;
in
{
  options.meta.ports = {
    list = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
    };
    assertUnique = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.assertUnique {
    assertions =
      let
        duplicatePorts =
          options.meta.ports.list.definitionsWithLocations
          |> lib.concatMap (
            entry:
            lib.map (port: {
              inherit (entry) file;
              inherit port;
            }) entry.value
          )
          |> lib.groupBy (entry: builtins.toString entry.port)
          |> lib.filterAttrs (port: entries: lib.length entries > 1);

        errorMessage =
          duplicatePorts
          |> lib.mapAttrsToList (
            port: entries:
            "Duplicate port ${port} found in:\n" + lib.concatMapStrings (entry: "  - ${entry.file}\n") entries
          )
          |> lib.concatStrings;
      in
      [
        {
          assertion = duplicatePorts == { };
          message = errorMessage;
        }
      ];
  };
}
