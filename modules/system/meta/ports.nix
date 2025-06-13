{
  config,
  options,
  lib,
  ...
}:
let
  cfg = config.meta.ports;

  duplicatedPorts =
    options.meta.ports.list.definitionsWithLocations
    |> lib.concatMap (
      entry:
      map (port: {
        file = entry.file;
        port = port;
      }) entry.value
    )
    |> lib.groupBy (entry: toString entry.port)
    |> lib.filterAttrs (port: entries: lib.length entries > 1);

  errorMessage =
    duplicatedPorts
    |> lib.mapAttrsToList (
      port: entries:
      "Duplicate port ${port} found in:\n" + lib.concatMapStrings (entry: "  - ${entry.file}\n") entries
    )
    |> lib.concatStrings;
in
{
  options.meta.ports = {
    list = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      internal = true;
    };
    assertUnique = lib.mkEnableOption "" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.assertUnique {
    assertions = [
      {
        assertion = duplicatedPorts == { };
        message = errorMessage;
      }
    ];
  };
}
