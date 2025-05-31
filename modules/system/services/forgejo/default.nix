{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.forgejo;

  user = config.users.users.forgejo.name;
  inherit (config.users.users.forgejo) group;
in
{
  options.custom.services.forgejo = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3003;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."forgejo/admin-password".owner = user;

    services.forgejo = {
      enable = true;
      lfs.enable = true;

      settings = {
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${config.services.forgejo.settings.server.DOMAIN}/";
          HTTP_PORT = cfg.port;
          LANDING_PAGE = "explore";
        };
        service.DISABLE_REGISTRATION = true;

        # https://forgejo.org/docs/latest/admin/recommendations
        database.SQLITE_JOURNAL_MODE = "WAL";
        cache = {
          ADAPTER = "twoqueue";
          HOST = ''{"size":100, "recent_ratio":0.25, "ghost_ratio":0.5}'';
        };
        "repository.signing".DEFAULT_TRUST_MODEL = "committer";
        security.LOGIN_REMEMBER_DAYS = 365;
      };
    };

    systemd.services.forgejo.preStart =
      let
        createCmd = "${lib.getExe config.services.forgejo.package} admin user create";
        passwordPath = config.sops.secrets."forgejo/admin-password".path;
      in
      ''${createCmd} --username SebastianStork --password "$(cat ${passwordPath})" --email "sebastian.stork@pm.me" --admin || true'';

    systemd.tmpfiles.rules =
      let
        disallow-all-robots = lib.replaceStrings [ "\n" ] [ "\\n" ] ''
          User-agent: *
          Disallow: /
        '';
      in
      [
        "d ${config.services.forgejo.customDir}/public 750 ${user} ${group} - -"
        "f+ ${config.services.forgejo.customDir}/public/robots.txt 750 ${user} ${group} - ${disallow-all-robots}"
      ];
  };
}
