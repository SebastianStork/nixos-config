{ lib, ... }:
{
  options.custom.meta.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            name = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = name;
            };
            url = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = "https://${name}";
            };
            icon = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = "";
            };
          };
        }
      )
    );
    default = { };
  };
}
