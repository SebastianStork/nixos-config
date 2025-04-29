{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.hedgedoc.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.hedgedoc.backups.enable {
    myConfig.resticBackup.hedgedoc = {
      healthchecks.enable = true;

      extraConfig = {
        backupPrepareCommand = "${lib.getExe' pkgs.systemd "systemctl"} stop hedgedoc.service";
        backupCleanupCommand = "${lib.getExe' pkgs.systemd "systemctl"} start hedgedoc.service";
        paths = with config.services.hedgedoc.settings; [
          uploadsPath
          db.storage
        ];
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "hedgedoc-restore";
        text = ''
          sudo bash -c "
            systemctl stop hedgedoc.service
            restic-hedgedoc restore latest --target /
            systemctl start hedgedoc.service
          "
        '';
      })
    ];
  };
}
