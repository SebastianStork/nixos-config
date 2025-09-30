{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.outline;

  dataDir = "/var/lib/outline";
  inherit (config.services.outline) user;
in
{
  options.custom.services.outline = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 32886;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    sops.secrets."outline/gitlab-auth-secret" = {
      owner = config.users.users.outline.name;
      restartUnits = [ "outline.service" ];
    };

    services.outline = {
      enable = true;
      publicUrl = "https://${cfg.domain}";
      inherit (cfg) port;
      forceHttps = false;
      storage.storageType = "local";

      # See https://docs.getoutline.com/s/hosting/doc/rate-limiter-HSqErsUgXH
      rateLimiter = {
        enable = true;
        requests = 1000;
      };

      # See https://docs.getoutline.com/s/hosting/doc/gitlab-GjNVvyv7vW
      oidcAuthentication =
        let
          baseURL = "https://code.fbi.h-da.de/oauth";
        in
        {
          clientId = "7b9f51553d695616888a945f74c31f35b58d0963955253e404ca6fc9a99e5cff";
          clientSecretFile = config.sops.secrets."outline/gitlab-auth-secret".path;
          authUrl = "${baseURL}/authorize";
          tokenUrl = "${baseURL}/token";
          userinfoUrl = "${baseURL}/userinfo";
          usernameClaim = "username";
          displayName = "GitLab";
          scopes = [
            "openid"
            "email"
          ];
        };
    };

    systemd.services.outline.enableStrictShellChecks = false;

    custom.services.resticBackups.outline = lib.mkIf cfg.doBackups {
      conflictingService = "outline.service";
      paths = [ dataDir ];
      extraConfig.backupPrepareCommand = ''
        ${lib.getExe pkgs.sudo} --user=${user} ${lib.getExe' config.services.postgresql.package "pg_dump"} outline --format=custom --file=${dataDir}/db.dump
      '';
      restoreCommand.postRestore = "sudo --user=${user} pg_restore --clean --if-exists --dbname outline ${dataDir}/db.dump";
    };

    custom.persist.directories = [
      dataDir
      config.services.postgresql.dataDir
    ];
  };
}
