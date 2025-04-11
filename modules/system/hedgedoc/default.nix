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
    services.hedgedoc = {
      enable = true;

      settings = {
        domain = "${cfg.subdomain}.${config.networking.domain}";
        inherit (cfg) port;
        protocolUseSSL = true;

        allowAnonymous = false;
        allowEmailRegister = false;
        defaultPermission = "limited";
      };
    };

    sops.secrets."hedgedoc/seb-password" = {
      owner = user;
      inherit group;
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
