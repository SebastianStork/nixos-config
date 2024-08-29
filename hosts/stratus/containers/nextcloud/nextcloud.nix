{
  config,
  pkgs,
  ...
}:
{
  systemd.tmpfiles.rules = [
    "z /run/secrets/nextcloud/admin-password 400 nextcloud nextcloud -"
    "z /data/postgresql 700 postgres postgres -"
  ];

  services.postgresql.dataDir = "/data/postgresql";

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    home = "/data/nextcloud";
    hostName = config.networking.fqdn;

    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/run/secrets/nextcloud/admin-password";
    };

    https = true;
    settings = {
      overwriteProtocol = "https";
      trusted_proxies = [ "127.0.0.1" ];
      log_type = "file";
      default_phone_region = "DE";
      maintenance_window_start = "2"; # UTC
    };

    configureRedis = true;
    maxUploadSize = "4G";
    phpOptions."opcache.interned_strings_buffer" = "16";

    autoUpdateApps = {
      enable = true;
      startAt = "04:00:00";
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) contacts calendar;
    };
  };
}
