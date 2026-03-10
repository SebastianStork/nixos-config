{ lib, ... }:
{
  options.custom.meta.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }:
        {
          options = {
            title = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = name;
            };
            domain = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = name;
            };
            url = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = "https://${config.domain}";
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
