{
  config,
  pkgs,
  lib,
  dataDir,
  ...
}:
{
  systemd.tmpfiles.rules = [ "d ${dataDir}/backup 750 forgejo forgejo -" ];

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

  myConfig.resticBackup.forgejo = {
    enable = true;
    user = config.users.users.forgejo.name;
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
      name = "forgejo-restore";
      text = ''
        systemctl stop forgejo.service
        sudo -u forgejo restic-forgejo restore --target / latest
        sudo -u forgejo pg_restore --clean --if-exists --dbname forgejo ${dataDir}/backup/db.dump
        systemctl start forgejo.service
      '';
    })
  ];
}
