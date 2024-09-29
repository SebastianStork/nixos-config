{ lib, ... }:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
  subdomain = "git";
in
{
  sops.secrets."container/forgejo/admin-password" = { };

  containers.${serviceName}.config =
    {
      config,
      lib,
      dataDir,
      ...
    }:
    let
      userName = config.services.forgejo.user;
      groupName = config.services.forgejo.group;
    in
    {
      imports = [ ./backup.nix ];

      systemd.tmpfiles.rules = [
        "z /run/secrets/container/forgejo/admin-password - ${userName} ${groupName} -"
        "d ${dataDir}/home 750 ${userName} ${groupName} -"
        "d ${dataDir}/postgresql 700 postgres postgres -"
      ];

      services.postgresql.dataDir = "${dataDir}/postgresql";

      services.forgejo = {
        enable = true;
        stateDir = "${dataDir}/home";

        lfs.enable = true;
        database.type = "postgres";
        settings = {
          server = {
            DOMAIN = config.networking.fqdn;
            ROOT_URL = "https://${config.services.forgejo.settings.server.DOMAIN}/";
          };
          service.DISABLE_REGISTRATION = true;
        };
      };

      systemd.services.forgejo.preStart = ''
        create="${lib.getExe config.services.forgejo.package} admin user create"
        $create --admin --email "sebastian.stork@pm.me" --username seb --password "$(cat /run/secrets/container/forgejo/admin-password)" || true
      '';

      myConfig.tailscale = {
        inherit subdomain;
        serve = "3000";
      };
    };
}
