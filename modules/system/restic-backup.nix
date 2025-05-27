{
  config,
  pkgs,
  lib,
  ...
}:
let
  backupServices = lib.filterAttrs (_: value: value.enable) config.custom.services.resticBackup;

  healthchecksEnable = (lib.filterAttrs (_: value: value.healthchecks.enable) backupServices) != { };
in
{
  options.custom.services.resticBackup = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "" // {
            default = true;
          };
          user = lib.mkOption {
            type = lib.types.str;
            default = config.users.users.root.name;
          };
          healthchecks.enable = lib.mkEnableOption "";
          extraConfig = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
        };
      }
    );
    default = { };
  };

  config = lib.mkIf (backupServices != { }) {
    users.groups.backup.members = builtins.filter (user: user != config.users.users.root.name) (
      lib.mapAttrsToList (_: value: value.user) backupServices
    );

    sops.secrets =
      let
        resticPermissions = {
          mode = "440";
          group = config.users.groups.backup.name;
        };
      in
      {
        "restic/environment" = resticPermissions;
        "restic/password" = resticPermissions;
        "healthchecks-ping-key" = lib.mkIf healthchecksEnable resticPermissions;
      };

    systemd.tmpfiles.rules = lib.mapAttrsToList (
      name: value:
      "d /var/cache/restic-backups-${name} 700 ${value.user} ${config.users.groups.backup.name} -"
    ) backupServices;

    services.restic.backups = lib.mapAttrs (
      name: value:
      lib.mkMerge [
        {
          inherit (value) user;
          initialize = true;
          repository = "s3:https://s3.eu-central-003.backblazeb2.com/stork-atlas/${name}";
          environmentFile = config.sops.secrets."restic/environment".path;
          passwordFile = config.sops.secrets."restic/password".path;
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 5"
            "--keep-monthly 6"
            "--keep-yearly 1"
          ];
          timerConfig = {
            OnCalendar = "03:00";
            RandomizedDelaySec = "1h";
          };
        }
        value.extraConfig
      ]
    ) backupServices;

    systemd.services = lib.mkMerge [
      (lib.mapAttrs' (
        name: _:
        lib.nameValuePair "restic-backups-${name}" {
          wants = [ "healthcheck-ping@${name}-backup_start.service" ];
          onSuccess = [ "healthcheck-ping@${name}-backup.service" ];
          onFailure = [ "healthcheck-ping@${name}-backup_fail.service" ];
        }
      ) (lib.filterAttrs (_: value: value.healthchecks.enable) backupServices))

      (lib.mkIf healthchecksEnable {
        "healthcheck-ping@" = {
          description = "Pings healthcheck (%i)";
          serviceConfig.Type = "oneshot";
          scriptArgs = "%i";
          script = ''
            ${lib.getExe pkgs.curl} --fail --silent --show-error --max-time 10 --retry 5  https://hc-ping.com/$(cat ${
              config.sops.secrets."healthchecks-ping-key".path
            })/$(echo $1 | tr _ /)
          '';
        };
      })
    ];
  };
}
