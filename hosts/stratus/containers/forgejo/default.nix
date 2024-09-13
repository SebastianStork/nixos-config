{
  containers.forgejo.config =
    {
      config,
      lib,
      dataDir,
      ...
    }:
    {
      imports = [ ./backup.nix ];

      sops.secrets."forgejo-admin-password" = {
        owner = config.users.users.forgejo.name;
        inherit (config.users.users.forgejo) group;
      };

      systemd.tmpfiles.rules = [
        "d ${dataDir}/home 710 nextcloud nextcloud -"
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
        $create --admin --email "sebastian.stork@pm.me" --username seb --password "$(cat ${config.sops.secrets.forgejo-admin-password.path})" || true
      '';

      myConfig.tailscale.serve = "3000";
    };
}
