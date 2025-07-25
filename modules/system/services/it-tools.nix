{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.it-tools;
in
{
  options.custom.services.it-tools = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8787;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.list = [ cfg.port ];
    };

    services.static-web-server = {
      enable = true;
      listen = "[::]:${builtins.toString cfg.port}";
      root = "${pkgs.it-tools}/lib";
      configuration.general.health = true;
    };
  };
}
