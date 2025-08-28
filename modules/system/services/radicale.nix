{ config, lib, ... }:
let
  cfg = config.custom.services.radicale;
in
{
  options.custom.services.radicale = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5232;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    sops = {
      secrets."radicale/admin-password" = { };
      templates."radicale/htpasswd" = {
        owner = config.users.users.radicale.name;
        content = "seb:${config.sops.placeholder."radicale/admin-password"}";
      };
    };

    services.radicale = {
      enable = true;
      settings = {
        server.hosts = "localhost:${builtins.toString cfg.port}";
        auth = {
          type = "htpasswd";
          htpasswd_filename = config.sops.templates."radicale/htpasswd".path;
          htpasswd_encryption = "plain";
        };
      };
    };
  };
}
