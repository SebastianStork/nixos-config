{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services.actualbudget;
in
{
  options.custom.services.actualbudget = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8888;
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.actual = { };
    users.users.actual = {
      isSystemUser = true;
      group = "actual";
    };

    services.actual = {
      enable = true;
      settings = {
        hostname = "localhost";
        inherit (cfg) port;
      };
    };
  };
}
