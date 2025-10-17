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
        |> lib.attrValues
        |> lib.map (value: value.config.meta.domains.list)
        |> lib.concatLists;
      readOnly = true;
    };
    validate = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.validate {
    assertions =
      let
        duplicateDomains =
          self.nixosConfigurations
          |> lib.attrValues
          |> lib.map (value: value.options.meta.domains.list.definitionsWithLocations)
          |> lib.concatLists
          |> lib.concatMap (
            entry:
            entry.value
            |> lib.map (domain: {
              file = entry.file |> lib.removePrefix "${self}/";
              inherit domain;
            })
          )
          |> builtins.groupBy (entry: toString entry.domain)
          |> lib.mapAttrs (_: values: values |> lib.map (value: value.file))
          |> lib.filterAttrs (_: files: lib.length files > 1);

        errorMessage =
          duplicateDomains
          |> lib.mapAttrsToList (
            domain: files:
            "Duplicate domain `${domain}` found in:\n"
            + (files |> lib.map (file: "  - ${file}") |> lib.concatLines)
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
