{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig.forgejo;

  user = config.users.users.forgejo.name;
in
{
  options.myConfig.forgejo = {
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
    sops.secrets."forgejo/admin-password".owner = user;

    services.forgejo = {
      enable = true;
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = "${cfg.subdomain}.${config.networking.domain}";
          ROOT_URL = "https://${config.services.forgejo.settings.server.DOMAIN}/";
          HTTP_PORT = cfg.port;
        };
        service.DISABLE_REGISTRATION = true;
      };
    };

    systemd.services.forgejo.preStart =
      let
        createCmd = "${lib.getExe config.services.forgejo.package} admin user create";
        passwordPath = config.sops.secrets."forgejo/admin-password".path;
      in
      ''${createCmd} --username SebastianStork --password "$(cat ${passwordPath})" --email "sebastian.stork@pm.me" --admin || true'';
  };
}
