{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.actualbudget.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.actualbudget.backups.enable {
    myConfig.resticBackup.actual = {
      enable = true;
      healthchecks.enable = true;

      extraConfig = {
        backupPrepareCommand = "${lib.getExe' pkgs.systemd "systemctl"} stop actual.service";
        backupCleanupCommand = "${lib.getExe' pkgs.systemd "systemctl"} start actual.service";
        paths = [ "/var/lib/actual" ];
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "actual-restore";
        text = ''
          sudo bash -c "
            systemctl stop actual.service
            restic-actual restore latest --target /
            systemctl start actual.service
          "
        '';
      })
    ];
  };
}
