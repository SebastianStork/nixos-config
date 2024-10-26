{ lib, ... }:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
  subdomain = "cloud";
in
{
  sops.secrets = {
    "container/nextcloud/admin-password" = { };
    "container/nextcloud/gmail-password" = { };
  };

  containers.${serviceName}.config =
    {
      config,
      inputs,
      pkgs,
      dataDir,
      ...
    }:
    let
      userName = config.users.users.nextcloud.name;
      groupName = config.users.users.nextcloud.group;
    in
    {
      imports = [
        ./email-server.nix
        ./backup.nix
      ];

      systemd.tmpfiles.rules = [
        "z /run/secrets/container/nextcloud/admin-password - ${userName} ${groupName} -"
        "d ${dataDir}/home 750 ${userName} ${groupName} -"
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
          adminpassFile = "/run/secrets/container/nextcloud/admin-password";
        };

        https = true;
        settings = {
          overwriteProtocol = "https";
          trusted_domains = [ "${subdomain}.${config.networking.domain}" ];
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

      environment.systemPackages = [ pkgs.ffmpeg ];

      myConfig.tailscale = {
        inherit subdomain;
        serve = "80";
      };
    };
}
