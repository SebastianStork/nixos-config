{
  config,
  lib,
  lib',
  ...
}:
let
  cfg = config.custom.services.freshrss;

  inherit (config.services.freshrss) dataDir;
in
{
  options.custom.services.freshrss = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 22055;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = lib'.isTailscaleDomain cfg.domain;
      message = lib'.mkUnprotectedMessage "FreshRSS";
    };

    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    services.freshrss = {
      enable = true;
      baseUrl = "https://${cfg.domain}";
      webserver = "caddy";
      virtualHost = ":${toString cfg.port}";
      defaultUser = "seb";
      authType = "none";
    };

    custom.persist.directories = [ dataDir ];
  };
}
