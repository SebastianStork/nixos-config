{
  config,
  pkgs,
  lib,
  ...
}:
let
  user = config.users.users.forgejo.name;
in
{
  options.custom.services.forgejo.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.forgejo.backups.enable {
    security.polkit = {
      enable = true;
      extraConfig =
        let
          service = "forgejo.service";
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

    custom.services.resticBackup.forgejo = {
      inherit user;
      healthchecks.enable = true;

      extraConfig = {
        backupPrepareCommand = "${lib.getExe' pkgs.systemd "systemctl"} stop forgejo.service";
        backupCleanupCommand = "${lib.getExe' pkgs.systemd "systemctl"} start forgejo.service";
        paths = [ config.services.forgejo.stateDir ];
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "forgejo-restore";
        text = ''
          sudo --user=${user} bash -c "
            systemctl stop forgejo.service
            restic-forgejo restore latest --target /
            systemctl start forgejo.service
          "
        '';
      })
    ];
  };
}
