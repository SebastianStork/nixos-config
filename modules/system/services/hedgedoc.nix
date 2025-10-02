{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.hedgedoc;
  dataDir = "/var/lib/hedgedoc";
in
{
  options.custom.services.hedgedoc = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    sops = {
      secrets."hedgedoc/gitlab-auth-secret" = { };
      templates."hedgedoc/environment" = {
        owner = config.users.users.hedgedoc.name;
        content = "GITLAB_CLIENTSECRET=${config.sops.placeholder."hedgedoc/gitlab-auth-secret"}";
        restartUnits = [ "hedgedoc.service" ];
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
    systemd.services.hedgedoc.preStart = lib.mkBefore ''
      secret_file="${dataDir}/session-secret"

      if [ ! -f $secret_file ]; then
        ${lib.getExe pkgs.pwgen} -s 64 1 > $secret_file
      fi

      SESSION_SECRET="$(cat $secret_file)"
      export SESSION_SECRET
    '';

    custom = {
      services.resticBackups.hedgedoc = lib.mkIf cfg.doBackups {
        conflictingService = "hedgedoc.service";
        paths = with config.services.hedgedoc.settings; [
          uploadsPath
          db.storage
        ];
      };

      persist.directories = [ dataDir ];
    };
  };
}
