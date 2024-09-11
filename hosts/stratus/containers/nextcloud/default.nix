{
  containers.nextcloud.config =
    {
      config,
      inputs,
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
            onlyoffice
            memories
            ;

          twofactor_totp = pkgs.fetchNextcloudApp {
            url = inputs.nextcloud-twofactor-totp.outPath;
            sha256 = inputs.nextcloud-twofactor-totp.narHash;
            license = "agpl3Plus";
            unpack = true;
          };
          news = pkgs.fetchNextcloudApp {
            url = inputs.nextcloud-news.outPath;
            sha256 = inputs.nextcloud-news.narHash;
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

      environment.systemPackages = [ pkgs.ffmpeg ];

      myConfig.tailscale.serve = "80";
    };
}
