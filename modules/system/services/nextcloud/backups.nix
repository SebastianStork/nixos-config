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

  nextcloud-occ = lib.getExe' config.services.nextcloud.occ "nextcloud-occ";
in
{
  options.custom.services.nextcloud.doBackups = lib.mkEnableOption "";

  config = lib.mkIf cfg.doBackups {
    custom.services.resticBackups.nextcloud = {
      extraConfig = {
        backupPrepareCommand = ''
          ${nextcloud-occ} maintenance:mode --on
          ${lib.getExe pkgs.sudo} --user=${user} ${lib.getExe' config.services.postgresql.package "pg_dump"} nextcloud --format=custom --file=${dataDir}/db.dump
        '';
        backupCleanupCommand = "${nextcloud-occ} maintenance:mode --off";
        paths = [
          "${dataDir}/data"
          "${dataDir}/config/config.php"
          "${dataDir}/db.dump"
        ];
      };

      restoreCommand = {
        preRestore = "${nextcloud-occ} maintenance:mode --on";
        postRestore = ''
          sudo --user=${user} pg_restore --clean --if-exists --dbname nextcloud ${dataDir}/db.dump
          ${nextcloud-occ} maintenance:mode --off
        '';
      };
    };
  };
}
