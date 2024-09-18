{ pkgs, lib, ... }:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
in
{
  myConfig.resticBackup.${serviceName} = {
    enable = true;
    healthchecks.enable = true;

    extraConfig = {
      backupPrepareCommand = "${lib.getExe' pkgs.systemd "systemctl"} stop docker-actualbudget.service";
      backupCleanupCommand = "${lib.getExe' pkgs.systemd "systemctl"} start docker-actualbudget.service docker-tailscale-actualbudget.service";
      paths = [ "/data/${serviceName}" ];
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "${serviceName}-restore";
      text = ''
        systemctl stop docker-actualbudget.service
        rm -rf /data/${serviceName}
        restic-${serviceName} restore --target / latest
        systemctl start docker-actualbudget.service docker-tailscale-actualbudget.service
      '';
    })
  ];
}
