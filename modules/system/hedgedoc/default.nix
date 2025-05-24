{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig.hedgedoc;

  user = config.users.users.hedgedoc.name;
  inherit (config.users.users.hedgedoc) group;

  manage_users = "CMD_CONFIG_FILE=/run/hedgedoc/config.json NODE_ENV=production ${lib.getExe' pkgs.hedgedoc "manage_users"}";
in
{
  options.myConfig.hedgedoc = {
    enable = lib.mkEnableOption "";
    subdomain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
        secrets = {
          "hedgedoc/seb-password" = {
            owner = user;
            inherit group;
          };
          "hedgedoc/gitlab-auth-secret" = {
            owner = user;
            inherit group;
          };
        };

        templates."hedgedoc/environment" = {
          owner = user;
          inherit group;
          content = "GITLAB_CLIENTSECRET=${config.sops.placeholder."hedgedoc/gitlab-auth-secret"}";
        };
      };

    services.hedgedoc = {
      enable = true;

      environmentFile = config.sops.templates."hedgedoc/environment".path;
      settings = {
        domain = "${cfg.subdomain}.${config.networking.domain}";
        inherit (cfg) port;
        protocolUseSSL = true;
        allowAnonymous = false;
        allowEmailRegister = false;
        defaultPermission = "limited";
        sessionSecret = "$SESSION_SECRET";
        gitlab = {
          baseURL = "https://code.fbi.h-da.de";
          clientID = "dc71d7ec1525ce3b425d7d41d602f67e1a06cef981259605a87841a6be62cc58";
          clientSecret = "$GITLAB_CLIENTSECRET";
        };
      };
    };

    systemd.services.hedgedoc = {
      # Ensure session-secret
      preStart = lib.mkBefore ''
        if [ ! -f /var/lib/hedgedoc/session-secret ]; then
          ${lib.getExe pkgs.pwgen} -s 64 1 > /var/lib/hedgedoc/session-secret
        fi
        export SESSION_SECRET=$(cat /var/lib/hedgedoc/session-secret)
      '';

      postStart =
        let
          manageUserSeb =
            mode:
            "${manage_users} --${mode} sebastian.stork@pm.me --pass \"$(cat ${
              config.sops.secrets."hedgedoc/seb-password".path
            })\"";
        in
        "${manageUserSeb "add"} || ${manageUserSeb "reset"}";
    };

    environment.shellAliases.hedgedoc-manage-users = "sudo --user=${user} ${manage_users}";
  };
}
