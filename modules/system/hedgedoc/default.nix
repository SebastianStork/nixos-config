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
        "hedgedoc/session-secret" = {
          owner = user;
          inherit group;
        };
        "hedgedoc/seb-password" = {
          owner = user;
          inherit group;
        };
      };

      templates."hedgedoc/environment".content = ''
        SESSION_SECRET=${config.sops.placeholder."hedgedoc/session-secret"}
      '';
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
      };
    };

    systemd.services.hedgedoc.postStart =
      let
        manageUserSeb =
          mode:
          "${manage_users} --${mode} sebastian.stork@pm.me --pass \"$(cat ${
            config.sops.secrets."hedgedoc/seb-password".path
          })\"";
      in
      "${manageUserSeb "add"} || ${manageUserSeb "reset"}";

    environment.shellAliases.hedgedoc-manage-users = "sudo --user=${user} ${manage_users}";
  };
}
