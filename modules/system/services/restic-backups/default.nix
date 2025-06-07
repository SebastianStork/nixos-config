{ config, lib, ... }:
let
  resticBackups = lib.filterAttrs (_: value: value.enable) config.custom.services.resticBackups;

  backupUsers = lib.mapAttrsToList (_: value: value.user) resticBackups;
in
{
  options.custom.services.resticBackups = lib.mkOption {
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
          suspendService = lib.mkOption {
            type = lib.types.nullOr lib.types.nonEmptyStr;
            default = null;
          };
          extraConfig = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
        };
      }
    );
    default = { };
  };

  config = lib.mkIf (resticBackups != { }) {
    assertions = [
      {
        assertion = lib.any (user: user != config.users.users.root.name) backupUsers;
        message = "restic shouldn't be run as root";
      }
    ];

    users.groups.backup.members = backupUsers;

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
      };

    services.restic.backups =
      resticBackups
      |> lib.mapAttrs (
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
      );

    systemd.services =
      resticBackups
      |> lib.mapAttrs' (
        name: value:
        lib.nameValuePair "restic-backups-${name}" (
          lib.mkIf (value.suspendService != null) {
            unitConfig.Conflicts = [ value.suspendService ];
            after = [ value.suspendService ];
            onSuccess = [ value.suspendService ];
            onFailure = [ value.suspendService ];
          }
        )
      );
  };
}
