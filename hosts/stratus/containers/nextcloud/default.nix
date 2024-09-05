{
  containers.nextcloud.config =
    {
      config,
      pkgs,
      dataDir,
      ...
    }:
    {
      imports = [
        ./email-server.nix
        ./backup.nix
      ];

      sops.secrets."nextcloud/admin-password" = {
        owner = config.users.users.nextcloud.name;
        inherit (config.users.users.nextcloud) group;
      };

      systemd.tmpfiles.rules = [
        "d ${dataDir}/home 750 nextcloud nextcloud -"
        "d ${dataDir}/postgresql 700 postgres postgres -"
      ];

      services.postgresql.dataDir = "${dataDir}/postgresql";

      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud29;
        home = "${dataDir}/home";
        hostName = config.networking.fqdn;

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
        };

        configureRedis = true;
        maxUploadSize = "16G";
        phpOptions."opcache.interned_strings_buffer" = "16";

        autoUpdateApps = {
          enable = true;
          startAt = "04:00:00";
        };
        extraApps = {
          inherit (config.services.nextcloud.package.packages.apps) contacts calendar onlyoffice;
        };
      };

      myConfig.tailscale.serve = "80";
    };
}
