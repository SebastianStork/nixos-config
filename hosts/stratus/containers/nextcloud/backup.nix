{
  config,
  pkgs,
  lib,
  dataDir,
  ...
}:
{
  systemd.tmpfiles.rules = [ "d ${dataDir}/backup 700 nextcloud nextcloud -" ];

  myConfig.resticBackup.nextcloud = {
    enable = true;
    user = config.users.users.nextcloud.name;

    extraConfig = {
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
