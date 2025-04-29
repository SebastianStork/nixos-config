{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig.nextcloud;

  dataDir = config.services.nextcloud.home;

  user = config.users.users.nextcloud.name;
  inherit (config.users.users.nextcloud) group;
in
{
  options.myConfig.nextcloud.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.backups.enable {
    systemd.tmpfiles.rules = [ "d ${dataDir}/backup 700 ${user} ${group} -" ];

    myConfig.resticBackup.nextcloud = {
      inherit user;
      healthchecks.enable = true;

      extraConfig = {
        backupPrepareCommand = ''
          ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --on
          ${lib.getExe' config.services.postgresql.package "pg_dump"} nextcloud --format=custom --file=${dataDir}/backup/db.dump
        '';
        backupCleanupCommand = "${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --off";
        paths = [
          "${dataDir}/data"
          "${dataDir}/config/config.php"
          "${dataDir}/backup"
        ];
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "nextcloud-restore";
        text = ''
          sudo --user=${user} bash -c "
            ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --on
            restic-nextcloud restore latest --target /
            pg_restore --clean --if-exists --dbname nextcloud ${dataDir}/backup/db.dump
            ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --off
          "
        '';
      })
    ];
  };
}
