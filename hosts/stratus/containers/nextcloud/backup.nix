{
  config,
  pkgs,
  lib,
  dataDir,
  ...
}:
{
  sops.secrets = {
    "restic/environment" = {
      owner = config.users.users.nextcloud.name;
      inherit (config.users.users.nextcloud) group;
    };
    "restic/password" = {
      owner = config.users.users.nextcloud.name;
      inherit (config.users.users.nextcloud) group;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir}/backup 700 nextcloud nextcloud -"
    "d /var/cache/restic-backups-nextcloud 700 nextcloud nextcloud -"
  ];

  services.restic.backups.nextcloud = {
    initialize = true;
    user = config.users.users.nextcloud.name;

    repository = "s3:https://s3.eu-central-003.backblazeb2.com/stork-atlas/nextcloud";
    environmentFile = config.sops.secrets."restic/environment".path;
    passwordFile = config.sops.secrets."restic/password".path;

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 6"
      "--keep-yearly 1"
    ];

    backupPrepareCommand = ''
      ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --on
      ${lib.getExe' config.services.postgresql.package "pg_dump"} nextcloud --format=custom --file=${dataDir}/backup/db.dump
    '';
    backupCleanupCommand = ''
      ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --off
    '';
    paths = [
      "${dataDir}/home/data"
      "${dataDir}/home/config/config.php"
      "${dataDir}/backup"
    ];
  };

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "nextcloud-restore";
      text = ''
        sudo -u nextcloud ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --on
        sudo -u nextcloud restic-nextcloud restore --target / latest
        sudo -u nextcloud pg_restore --clean --if-exists --dbname nextcloud ${dataDir}/backup/db.dump
        sudo -u nextcloud ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --off
      '';
    })
  ];
}
