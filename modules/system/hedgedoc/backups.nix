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
        backupPrepareCommand = ''
          ${lib.getExe' pkgs.systemd "systemctl"} stop hedgedoc.service
        '';
        backupCleanupCommand = ''
          ${lib.getExe' pkgs.systemd "systemctl"} start hedgedoc.service
        '';
        paths = [ "/var/lib/hedgedoc" ];
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "hedgedoc-restore";
        text = ''
          sudo systemctl stop hedgedoc.service
          sudo restic-hedgedoc restore --target / latest
          sudo systemctl start hedgedoc.service
        '';
      })
    ];
  };
}
