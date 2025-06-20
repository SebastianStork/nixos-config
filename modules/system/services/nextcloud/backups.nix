{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.nextcloud;

  user = config.users.users.nextcloud.name;
  dataDir = config.services.nextcloud.home;
in
{
  options.custom.services.nextcloud.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.backups.enable {
    custom.services.resticBackups.nextcloud = {
      extraConfig = {
        backupPrepareCommand = ''
          ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --on
          ${lib.getExe pkgs.sudo} --user=${user} ${lib.getExe' config.services.postgresql.package "pg_dump"} nextcloud --format=custom --file=${dataDir}/db.dump
        '';
        backupCleanupCommand = "${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --off";
        paths = [
          "${dataDir}/data"
          "${dataDir}/config/config.php"
          "${dataDir}/db.dump"
        ];
      };

      restoreCommand = {
        preRestore = "${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --on";
        postRestore = ''
          sudo --user=${user} pg_restore --clean --if-exists --dbname nextcloud ${dataDir}/db.dump
          ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --off
        '';
      };
    };
  };
}
