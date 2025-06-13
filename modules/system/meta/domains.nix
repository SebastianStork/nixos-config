{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.meta.domains;

  duplicatedDomains =
    self.nixosConfigurations
    |> lib.mapAttrsToList (_: value: value.options.meta.domains.list.definitionsWithLocations)
    |> lib.concatLists
    |> lib.concatMap (
      entry:
      map (domain: {
        file = entry.file;
        inherit domain;
      }) entry.value
    )
    |> lib.groupBy (entry: toString entry.domain)
    |> lib.filterAttrs (domain: entries: lib.length entries > 1);

  errorMessage =
    duplicatedDomains
    |> lib.mapAttrsToList (
      domain: entries:
      "Duplicate domain \"${domain}\" found in:\n"
      + lib.concatMapStrings (entry: "  - ${entry.file}\n") entries
    )
    |> lib.concatStrings;
in
{
  options.meta.domains = {
    list = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
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
        assertion = duplicatedDomains == { };
        message = errorMessage;
      }
    ];
  };
}
