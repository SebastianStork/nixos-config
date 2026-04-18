{ lib, ... }:
{
  options.custom.meta.sites = lib.mkOption {
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
            path = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
            url = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = "https://${config.domain}${config.path}";
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
