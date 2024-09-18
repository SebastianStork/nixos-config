{
  config,
  pkgs,
  lib,
  dataDir,
  ...
}:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
  userName = config.services.forgejo.user;
  groupName = config.services.forgejo.group;
in
{
  systemd.tmpfiles.rules = [ "d ${dataDir}/backup 750 ${userName} ${groupName} -" ];

  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "forgejo.service" &&
          subject.user == "forgejo") {
          return polkit.Result.YES;
        }
      });
    '';
  };

  myConfig.resticBackup.${serviceName} = {
    enable = true;
    user = userName;
    healthchecks.enable = true;

    extraConfig = {
      backupPrepareCommand = ''
        ${lib.getExe' pkgs.systemd "systemctl"} stop forgejo.service
        ${lib.getExe' config.services.postgresql.package "pg_dump"} forgejo --format=custom --file=${dataDir}/backup/db.dump
      '';
      backupCleanupCommand = ''
        ${lib.getExe' pkgs.systemd "systemctl"} start forgejo.service
      '';
      paths = [
        "${dataDir}/home/custom"
        "${dataDir}/home/data"
        "${dataDir}/home/repositories"
        "${dataDir}/home/.ssh"
        "${dataDir}/backup"
      ];
      extraBackupArgs = [ "--exclude='${dataDir}/home/custom/conf/app.ini'" ];
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "${serviceName}-restore";
      text = ''
        systemctl stop forgejo.service
        sudo -u ${userName} restic-${serviceName} restore --target / latest
        sudo -u ${userName} pg_restore --clean --if-exists --dbname forgejo ${dataDir}/backup/db.dump
        systemctl start forgejo.service
      '';
    })
  ];
}
