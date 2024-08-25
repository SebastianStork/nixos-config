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

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud29;
      home = "/data/nextcloud";
      hostName = config.networking.fqdn;

      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) contacts calendar;
      };

      database.createLocally = true;
      config = {
        dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = config.sops.secrets."nextcloud/admin-pass".path;
      };

      settings = {
        log_type = "file";
        default_phone_region = "DE";
      };
    };
  };
}
