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
    local = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
    };
    global = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default =
        self.nixosConfigurations
        |> lib.attrValues
        |> lib.map (host: host.config.meta.domains.local)
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
          |> lib.map (host: host.options.meta.domains.local.definitionsWithLocations)
          |> lib.concatLists
          |> lib.concatMap (
            { file, value }:
            value
            |> lib.map (domain: {
              file = self.lib.relativePath file;
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
      lib.singleton {
        assertion = duplicateDomains == { };
        message = errorMessage;
      };
  };
}
