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
            entry.value
            |> lib.map (domain: {
              file = entry.file |> lib.removePrefix "${self}/";
              inherit domain;
            })
          )
          |> lib.groupBy (entry: builtins.toString entry.domain)
          |> lib.filterAttrs (_: entries: lib.length entries > 1);

        errorMessage =
          duplicateDomains
          |> lib.mapAttrsToList (
            domain: entries:
            "Duplicate domain \"${domain}\" found in:\n"
            + (entries |> lib.map (entry: "  - ${entry.file}") |> lib.concatLines)
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
