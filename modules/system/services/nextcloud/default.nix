{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.nextcloud;

  user = config.users.users.nextcloud.name;
in
{
  options.custom.services.nextcloud = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 80;
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports = {
        tcp.list = [ cfg.port ];
        udp.list = [ config.services.postgresql.settings.port ];
      };
    };

    sops.secrets."nextcloud/admin-password".owner = user;

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      hostName = cfg.domain;

      database.createLocally = true;
      config = {
        dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
      };

      https = true;
      settings = {
        overwriteProtocol = "https";
        trusted_proxies = [ "localhost" ];
        log_type = "file";
        default_phone_region = "DE";
        maintenance_window_start = "2"; # UTC
      };

      configureRedis = true;
      maxUploadSize = "16G";
      phpOptions."opcache.interned_strings_buffer" = "16";

      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps)
          calendar
          contacts
          ;

        twofactor_totp = pkgs.fetchNextcloudApp {
          url = inputs.nextcloud-twofactor-totp.outPath;
          sha256 = inputs.nextcloud-twofactor-totp.narHash;
          license = "agpl3Plus";
          unpack = true;
        };
      };
    };
  };
}
