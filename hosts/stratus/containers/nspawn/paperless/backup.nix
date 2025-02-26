{
  config,
  pkgs,
  lib,
  dataDir,
  ...
}:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
  userName = config.services.paperless.user;
  groupName = config.users.users.${userName}.group;
in
{
  systemd.tmpfiles.rules = [ "d ${dataDir}/backup 700 ${userName} ${groupName} -" ];

  users.users.paperless.extraGroups = [ "redis-paperless" ];

  myConfig.resticBackup.${serviceName} = {
    enable = true;
    user = userName;
    healthchecks.enable = true;

    extraConfig = {
      backupPrepareCommand = ''
        ${dataDir}/paperless-manage document_exporter ${dataDir}/backup ${
          lib.concatStringsSep " " [
            "--compare-checksums"
            "--delete"
            "--split-manifest"
            "--use-filename-format"
            "--no-progress-bar"
          ]
        }
      '';
      paths = [ "${dataDir}/backup" ];
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "${serviceName}-restore";
      text = ''
        sudo --user=${userName} restic-${serviceName} restore --target / latest
        sudo --user=${userName} ${dataDir}/paperless-manage document_importer ${dataDir}/backup
      '';
    })
  ];
}
