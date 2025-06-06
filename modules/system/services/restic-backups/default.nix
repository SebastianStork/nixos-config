{
  config,
  pkgs,
  lib,
  ...
}:
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

    security.polkit = {
      enable = resticBackups |> lib.attrValues |> lib.any (value: value.suspendService != null);
      extraConfig =
        let
          mkAllowRule = service: user: ''
            polkit.addRule(function(action, subject) {
              if (action.id == "org.freedesktop.systemd1.manage-units" &&
                action.lookup("unit") == "${service}" &&
                subject.user == "${user}") {
                return polkit.Result.YES;
              }
            });
          '';
        in
        resticBackups
        |> lib.attrValues
        |> lib.filter (value: value.suspendService != null)
        |> lib.map (value: mkAllowRule value.suspendService value.user)
        |> lib.concatLines;
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
            backupPrepareCommand = lib.mkIf (value.suspendService != null) (
              lib.mkBefore "${lib.getExe' pkgs.systemd "systemctl"} stop ${value.suspendService}"
            );
            backupCleanupCommand = lib.mkIf (value.suspendService != null) (
              lib.mkAfter "${lib.getExe' pkgs.systemd "systemctl"} start ${value.suspendService}"
            );
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
  };
}
