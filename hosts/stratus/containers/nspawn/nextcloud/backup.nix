{
  config,
  pkgs,
  lib,
  dataDir,
  ...
}:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
  userName = config.users.users.nextcloud.name;
  groupName = config.users.users.nextcloud.group;
in
{
  systemd.tmpfiles.rules = [ "d ${dataDir}/backup 700 ${userName} ${groupName} -" ];

  myConfig.resticBackup.${serviceName} = {
    enable = true;
    user = userName;
    healthchecks.enable = true;

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
      name = "${serviceName}-restore";
      text = ''
        sudo --user=${userName} ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --on
        sudo --user=${userName} restic-${serviceName} restore --target / latest
        sudo --user=${userName} pg_restore --clean --if-exists --dbname nextcloud ${dataDir}/backup/db.dump
        sudo --user=${userName} ${lib.getExe' config.services.nextcloud.occ "nextcloud-occ"} maintenance:mode --off
      '';
    })
  ];
}
