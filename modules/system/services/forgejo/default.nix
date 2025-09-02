{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.services.forgejo;
in
{
  options.custom.services.forgejo = {
    enable = lib.mkEnableOption "";
    doBackups = lib.mkEnableOption "";
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
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    sops.secrets."forgejo/admin-password".owner = config.users.users.forgejo.name;

    services.forgejo = {
      enable = true;
      package = pkgs-unstable.forgejo;

      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}/";
          HTTP_PORT = cfg.port;
          LANDING_PAGE = "/SebastianStork";
        };
        service.DISABLE_REGISTRATION = true;
        session.PROVIDER = "db";
        mirror.DEFAULT_INTERVAL = "1h";
        other = {
          SHOW_FOOTER_VERSION = false;
          SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
          SHOW_FOOTER_POWERED_BY = false;
        };

        cron.ENABLED = true;
        "cron.git_gc_repos".ENABLED = true;

        repository.ENABLE_PUSH_CREATE_USER = true;

        # https://forgejo.org/docs/latest/admin/recommendations
        database.SQLITE_JOURNAL_MODE = "WAL";
        cache = {
          ADAPTER = "twoqueue";
          HOST = lib.strings.toJSON {
            size = 100;
            recent_ratio = 0.25;
            ghost_ratio = 0.5;
          };
        };
        "repository.signing".DEFAULT_TRUST_MODEL = "committer";
        security.LOGIN_REMEMBER_DAYS = 365;
      };
    };

    systemd = {
      services.forgejo.preStart =
        let
          userCmd = "${lib.getExe config.services.forgejo.package} admin user";
          credentials = lib.concatStringsSep " " [
            "--username SebastianStork"
            "--password \"$PASSWORD\""
          ];
        in
        ''
          PASSWORD="$(< ${config.sops.secrets."forgejo/admin-password".path})"

          ${userCmd} create ${credentials} --email "sebastian.stork@pm.me" --admin \
            || ${userCmd} change-password ${credentials} --must-change-password=false
        '';
    };

    custom.services.resticBackups.forgejo = lib.mkIf cfg.doBackups {
      conflictingService = "forgejo.service";
      paths = [ config.services.forgejo.stateDir ];
    };
  };
}
