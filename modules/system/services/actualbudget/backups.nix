{
  config,
  pkgs,
  lib,
  ...
}:
let
  user = config.users.users.actual.name;
in
{
  options.custom.services.actualbudget.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.actualbudget.backups.enable {
    security.polkit = {
      enable = true;
      extraConfig =
        let
          service = "actual.service";
        in
        ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
              action.lookup("unit") == "${service}" &&
              subject.user == "${user}") {
              return polkit.Result.YES;
            }
          });
        '';
    };

    custom.services.resticBackup.actual = {
      inherit user;
      healthchecks.enable = true;

      extraConfig = {
        backupPrepareCommand = "${lib.getExe' pkgs.systemd "systemctl"} stop actual.service";
        backupCleanupCommand = "${lib.getExe' pkgs.systemd "systemctl"} start actual.service";
        paths = [ config.services.actual.settings.dataDir ];
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "actual-restore";
        text = ''
          sudo --user=${user} bash -c "
            systemctl stop actual.service
            restic-actual restore latest --target /
            systemctl start actual.service
          "
        '';
      })
    ];
  };
}
