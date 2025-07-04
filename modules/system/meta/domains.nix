{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.meta.domains;
in
{
  options.meta.domains = {
    list = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
    };
    globalList = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default =
        self.nixosConfigurations
        |> lib.mapAttrsToList (_: value: value.config.meta.domains.list)
        |> lib.concatLists;
      readOnly = true;
    };
    assertUnique = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.assertUnique {
    assertions =
      let
        duplicateDomains =
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
          duplicateDomains
          |> lib.mapAttrsToList (
            domain: entries:
            "Duplicate domain \"${domain}\" found in:\n"
            + lib.concatMapStrings (entry: "  - ${entry.file}\n") entries
          )
          |> lib.concatStrings;
      in
      [
        {
          assertion = duplicateDomains == { };
          message = errorMessage;
        }
      ];
  };
}
