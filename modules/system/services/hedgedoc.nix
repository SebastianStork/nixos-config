{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.hedgedoc;
in
{
  options.custom.services.hedgedoc = {
    enable = lib.mkEnableOption "";
    doBackups = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.list = [ cfg.port ];
    };

    sops =
      let
        owner = config.users.users.hedgedoc.name;
      in
      {
        secrets."hedgedoc/gitlab-auth-secret".owner = owner;
        templates."hedgedoc/environment" = {
          inherit owner;
          content = "GITLAB_CLIENTSECRET=${config.sops.placeholder."hedgedoc/gitlab-auth-secret"}";
        };
      };

    services.hedgedoc = {
      enable = true;

      environmentFile = config.sops.templates."hedgedoc/environment".path;
      settings = {
        inherit (cfg) domain port;
        protocolUseSSL = true;
        allowAnonymous = false;
        email = false;
        defaultPermission = "limited";
        sessionSecret = "$SESSION_SECRET";
        gitlab = {
          baseURL = "https://code.fbi.h-da.de";
          clientID = "dc71d7ec1525ce3b425d7d41d602f67e1a06cef981259605a87841a6be62cc58";
          clientSecret = "$GITLAB_CLIENTSECRET";
        };
      };
    };

    # Ensure session-secret
    systemd.services.hedgedoc.preStart =
      let
        sessionSecret = "/var/lib/hedgedoc/session-secret";
      in
      lib.mkBefore ''
        if [ ! -f ${sessionSecret} ]; then
          ${lib.getExe pkgs.pwgen} -s 64 1 > ${sessionSecret}
        fi
        export SESSION_SECRET=$(cat ${sessionSecret})
      '';

    custom.services.resticBackups.hedgedoc = lib.mkIf cfg.doBackups {
      conflictingService = "hedgedoc.service";
      extraConfig.paths =
        let
          hedgedocSettings = config.services.hedgedoc.settings;
        in
        [
          hedgedocSettings.uploadsPath
          hedgedocSettings.db.storage
        ];
    };
  };
}
