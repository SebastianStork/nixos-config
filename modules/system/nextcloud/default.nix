{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.nextcloud.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.nextcloud.enable {
    sops.secrets."nextcloud/admin-pass" = {
      owner = config.services.nextcloud.config.dbname;
      group = config.services.nextcloud.config.dbuser;
    };

    services = {
      nextcloud = {
        enable = true;
        package = pkgs.nextcloud29;
        home = "/data/nextcloud";
        hostName = config.networking.fqdn;
        configureRedis = true;

        database.createLocally = true;
        config = {
          dbtype = "pgsql";
          adminuser = "admin";
          adminpassFile = config.sops.secrets."nextcloud/admin-pass".path;
        };

        https = true;
        settings = {
          overwriteProtocol = "https";
          trusted_proxies = [ "127.0.0.1" ];
          log_type = "file";
          default_phone_region = "DE";
          maintenance_window_start = "2"; # UTC
        };

        phpOptions."opcache.interned_strings_buffer" = "16";

        autoUpdateApps = {
          enable = true;
          startAt = "04:00:00";
        };
        extraApps = {
          inherit (config.services.nextcloud.package.packages.apps) contacts calendar;
        };
      };

      nginx = {
        enable = true;
        virtualHosts.${config.services.nextcloud.hostName}.listen = [
          {
            addr = "0.0.0.0";
            port = 8080;
          }
        ];
      };

      tailscale.permitCertUid = "caddy";
      caddy = {
        enable = true;
        virtualHosts.${config.services.nextcloud.hostName}.extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };
    };
  };
}
