{
  config,
  pkgs,
  lib,
  dataDir,
  ...
}:
{
  systemd.tmpfiles.rules = [ "d ${dataDir}/backup 700 paperless paperless -" ];

  users.users.paperless.extraGroups = [ "redis-paperless" ];

  myConfig.resticBackup.paperless = {
    enable = true;
    user = config.users.users.paperless.name;
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
      name = "paperless-restore";
      text = ''
        sudo -u paperless restic-paperless restore --target / latest
        sudo -u paperless ${dataDir}/paperless-manage document_importer ${dataDir}/backup
      '';
    })
  ];
}
