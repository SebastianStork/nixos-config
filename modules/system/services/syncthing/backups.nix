{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.syncthing;

  user = config.users.users.syncthing.name;
in
{
  options.custom.services.syncthing.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.backups.enable {
    assertions = [
      {
        assertion = cfg.isServer;
        message = "syncthing backups can only be made on a server";
      }
    ];

    security.polkit = {
      enable = true;
      extraConfig =
        let
          service = "syncthing.service";
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

    custom.services.resticBackups.syncthing = {
      inherit user;
      healthchecks.enable = true;

      extraConfig = {
        backupPrepareCommand = "${lib.getExe' pkgs.systemd "systemctl"} stop syncthing.service";
        backupCleanupCommand = "${lib.getExe' pkgs.systemd "systemctl"} start syncthing.service";
        paths = [ config.services.syncthing.dataDir ];
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "syncthing-restore";
        text = ''
          sudo --user=${user} bash -c "
            systemctl stop syncthing.service
            restic-syncthing restore latest --target /
            systemctl start syncthing.service
          "
        '';
      })
    ];
  };
}
