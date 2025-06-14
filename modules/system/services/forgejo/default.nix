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
    meta.ports.list = [ cfg.port ];

    sops.secrets."forgejo/admin-password".owner = user;

    services.forgejo = {
      enable = true;
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
        federation.ENABLED = true;
        other = {
          SHOW_FOOTER_VERSION = false;
          SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
          SHOW_FOOTER_POWERED_BY = false;
        };

        cron.ENABLED = true;
        "cron.git_gc_repos".ENABLED = true;

        # https://forgejo.org/docs/latest/admin/recommendations
        database.SQLITE_JOURNAL_MODE = "WAL";
        cache = {
          ADAPTER = "twoqueue";
          HOST = builtins.toJSON {
            size = 100;
            recent_ratio = 0.25;
            ghost_ratio = 0.5;
          };
        };
        "repository.signing".DEFAULT_TRUST_MODEL = "committer";
        security.LOGIN_REMEMBER_DAYS = 365;
      };
    };

    systemd.services.forgejo.preStart =
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

    systemd.tmpfiles.rules =
      let
        disallow-all-robots = pkgs.writeText "disallow-all-robots.txt" ''
          User-agent: *
          Disallow: /
        '';
      in
      [
        "d ${config.services.forgejo.customDir}/public 750 ${user} ${group} - -"
        "L+ ${config.services.forgejo.customDir}/public/robots.txt 750 - - - ${disallow-all-robots}"
      ];

    custom.services.gatus.endpoints = {
      "Forgejo" = {
        group = "Public";
        url = "https://${cfg.domain}/api/healthz";
        extraConditions = [ "[BODY].status == pass" ];
      };
      "Forgejo SSH" = {
        group = "Public";
        url = "ssh://${cfg.domain}";
      };
    };
  };
}
