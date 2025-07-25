{ config, lib, ... }:
let
  cfg = config.custom.services.ntfy;
in
{
  options.custom.services.ntfy = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 2586;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.list = [ cfg.port ];
    };

    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://${cfg.domain}";
        listen-http = ":${builtins.toString cfg.port}";
        behind-proxy = true;
        web-root = "disable";
      };
    };
  };
}
