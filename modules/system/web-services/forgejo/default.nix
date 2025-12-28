{ config, lib, ... }:
let
  cfg = config.custom.web-services.forgejo;
in
{
  options.custom.web-services.forgejo = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3003;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.local = [ cfg.domain ];
      ports.tcp = [ cfg.port ];
    };

    users = {
      users.git = {
        isSystemUser = true;
        useDefaultShell = true;
        group = config.users.groups.git.name;
        home = config.services.forgejo.stateDir;
      };
      groups.git = { };
    };

    services.forgejo = {
      enable = true;

      user = "git";
      group = "git";

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

    # Create user: `forgejo-user create --admin --username NAME --email EMAIL --password PASSWORD`
    environment.shellAliases.forgejo-user = "sudo --user=${config.services.forgejo.user} ${lib.getExe config.services.forgejo.package} admin user --config /var/lib/forgejo/custom/conf/app.ini";

    custom = {
      services = {
        caddy.virtualHosts.${cfg.domain}.port = cfg.port;

        restic.backups.forgejo = lib.mkIf cfg.doBackups {
          conflictingService = "forgejo.service";
          paths = [ config.services.forgejo.stateDir ];
        };
      };

      persistence.directories = [ config.services.forgejo.stateDir ];
    };
  };
}
