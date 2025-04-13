{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig.syncthing;
in
{
  options.myConfig.syncthing.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.backups.enable {
    assertions = [
      {
        assertion = cfg.isServer;
        message = "syncthing backups can only be made on a server";
      }
    ];

    myConfig.resticBackup.syncthing = {
      healthchecks.enable = true;

      extraConfig = {
        backupPrepareCommand = "${lib.getExe' pkgs.systemd "systemctl"} stop syncthing.service";
        backupCleanupCommand = "${lib.getExe' pkgs.systemd "systemctl"} start syncthing.service";
        paths = [ "/var/lib/syncthing" ];
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "syncthing-restore";
        text = ''
          sudo bash -c "
            systemctl stop syncthing.service
            restic-syncthing restore latest --target /
            systemctl start syncthing.service
          "
        '';
      })
    ];
  };
}
