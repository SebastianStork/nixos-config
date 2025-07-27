{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.hedgedoc;

  user = config.users.users.hedgedoc.name;
  dataDir = "/var/lib/hedgedoc";

  manageUsers = "CMD_CONFIG_FILE=/run/hedgedoc/config.json NODE_ENV=production ${lib.getExe' pkgs.hedgedoc "manage_users"}";
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

    sops = {
      secrets = {
        "hedgedoc/seb-password".owner = user;
        # "hedgedoc/gitlab-auth-secret".owner = user;
      };

      # templates."hedgedoc/environment" = {
      #   owner = user;
      #   content = "GITLAB_CLIENTSECRET=${config.sops.placeholder."hedgedoc/gitlab-auth-secret"}";
      # };
    };

    services.hedgedoc = {
      enable = true;

      # environmentFile = config.sops.templates."hedgedoc/environment".path;
      settings = {
        inherit (cfg) domain port;
        protocolUseSSL = true;
        allowAnonymous = false;
        allowEmailRegister = false;
        defaultPermission = "limited";
        sessionSecret = "$SESSION_SECRET";
        # gitlab = {
        #   baseURL = "https://code.fbi.h-da.de";
        #   clientID = "dc71d7ec1525ce3b425d7d41d602f67e1a06cef981259605a87841a6be62cc58";
        #   clientSecret = "$GITLAB_CLIENTSECRET";
        # };
      };
    };

    systemd.services.hedgedoc = {
      # Ensure session-secret
      preStart = lib.mkBefore ''
        if [ ! -f ${dataDir}/session-secret ]; then
          ${lib.getExe pkgs.pwgen} -s 64 1 > ${dataDir}/session-secret
        fi
        export SESSION_SECRET=$(cat ${dataDir}/session-secret)
      '';

      postStart =
        let
          manageUserSeb =
            mode:
            "${manageUsers} --${mode} sebastian.stork@pm.me --pass \"$(cat ${
              config.sops.secrets."hedgedoc/seb-password".path
            })\"";
        in
        "${manageUserSeb "add"} || ${manageUserSeb "reset"}";
    };

    environment.shellAliases.hedgedoc-manage-users = "sudo --user=${user} ${manageUsers}";

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
