{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig.nextcloud;

  user = config.users.users.nextcloud.name;
  inherit (config.users.users.nextcloud) group;
in
{
  options.myConfig.nextcloud = {
    enable = lib.mkEnableOption "";
    subdomain = lib.mkOption {
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
    sops.secrets."nextcloud/admin-password" = {
      owner = user;
      inherit group;
    };

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      hostName = "${cfg.subdomain}.${config.networking.domain}";

      database.createLocally = true;
      config = {
        dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
      };

      https = true;
      settings = {
        overwriteProtocol = "https";
        trusted_proxies = [ "127.0.0.1" ];
        log_type = "file";
        default_phone_region = "DE";
        maintenance_window_start = "2"; # UTC
        defaultapp = "side_menu";
      };

      configureRedis = true;
      maxUploadSize = "16G";
      phpOptions."opcache.interned_strings_buffer" = "16";

      autoUpdateApps = {
        enable = true;
        startAt = "04:00:00";
      };
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps)
          calendar
          contacts
          deck
          onlyoffice
          ;

        twofactor_totp = pkgs.fetchNextcloudApp {
          url = inputs.nextcloud-twofactor-totp.outPath;
          sha256 = inputs.nextcloud-twofactor-totp.narHash;
          license = "agpl3Plus";
          unpack = true;
        };
        side_menu = pkgs.fetchNextcloudApp {
          url = inputs.nextcloud-side-menu.outPath;
          sha256 = inputs.nextcloud-side-menu.narHash;
          license = "agpl3Plus";
          unpack = true;
        };
      };
    };
  };
}
