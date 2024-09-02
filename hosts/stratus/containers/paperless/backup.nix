{
  config,
  pkgs,
  lib,
  dataDir,
  ...
}:
{
  sops.secrets = {
    "restic/environment" = {
      owner = config.users.users.paperless.name;
      inherit (config.users.users.paperless) group;
    };
    "restic/password" = {
      owner = config.users.users.paperless.name;
      inherit (config.users.users.paperless) group;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir}/backup 700 paperless paperless -"
    "d /var/cache/restic-backups-paperless 700 paperless paperless -"
  ];

  services.restic.backups.paperless = {
    inherit (config.services.paperless) user;
    initialize = true;

    repository = "s3:https://s3.eu-central-003.backblazeb2.com/stork-atlas/paperless";
    environmentFile = config.sops.secrets."restic/environment".path;
    passwordFile = config.sops.secrets."restic/password".path;

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 6"
      "--keep-yearly 1"
    ];

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

  users.users.paperless.extraGroups = [ "redis-paperless" ];
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "restore-paperless";
      text = ''
        sudo -u paperless restic-paperless restore --target / latest
        sudo -u paperless ${dataDir}/paperless-manage document_importer ${dataDir}/backup
      '';
    })
  ];
}
