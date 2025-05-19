{
  config,
  pkgs,
  lib,
  ...
}:
let
  user = config.users.users.hedgedoc.name;
in
{
  options.myConfig.hedgedoc.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.hedgedoc.backups.enable {
    security.polkit = {
      enable = true;
      extraConfig =
        let
          service = "hedgedoc.service";
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

    myConfig.resticBackup.hedgedoc = {
      inherit user;
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
          sudo --user=${user} bash -c "
            systemctl stop hedgedoc.service
            restic-hedgedoc restore latest --target /
            systemctl start hedgedoc.service
          "
        '';
      })
    ];
  };
}
