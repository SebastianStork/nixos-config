{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.nextcloud;

  dataDir = config.services.nextcloud.home;
  user = config.users.users.nextcloud.name;
in
{
  options.custom.services.nextcloud.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.backups.enable {
    custom.services.resticBackups.nextcloud = {
      inherit user;
      extraConfig = {
        backupPrepareCommand = ''
          ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --on
          ${lib.getExe' config.services.postgresql.package "pg_dump"} nextcloud --format=custom --file=${dataDir}/db.dump
        '';
        backupCleanupCommand = "${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --off";
        paths = [
          "${dataDir}/data"
          "${dataDir}/config/config.php"
          "${dataDir}/db.dump"
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
            pg_restore --clean --if-exists --dbname nextcloud ${dataDir}/db.dump
            ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --off
          "
        '';
      })
    ];
  };
}
