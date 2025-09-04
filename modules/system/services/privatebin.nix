{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.services.privatebin;
in
{
  options.custom.services.privatebin = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 61009;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    services = {
      privatebin = {
        enable = true;
        package = pkgs-unstable.privatebin; # Unstable to get version 2.0
        enableNginx = true;
        virtualHost = "privatebin";
        settings.main.basepath = "https://${cfg.domain}";
      };

      nginx.virtualHosts.privatebin.listen = [
        {
          addr = "localhost";
          inherit (cfg) port;
        }
      ];
    };
  };
}
