{ config, lib, ... }:
let
  resticBackups = lib.filterAttrs (_: value: value.enable) config.custom.services.resticBackups;
in
{
  options.custom.services.resticBackups = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "" // {
            default = true;
          };
          conflictingService = lib.mkOption {
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
    sops = {
      secrets = {
        "restic/backblaze/key-id" = { };
        "restic/backblaze/application-key" = { };
        "restic/password" = { };
      };

      templates."restic/environment".content = ''
        AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/backblaze/key-id"}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/backblaze/application-key"}
      '';
    };

    systemd.tmpfiles.rules =
      resticBackups |> lib.mapAttrsToList (name: _: "d /var/cache/restic-backups-${name} 700 - - -");

    services.restic.backups =
      resticBackups
      |> lib.mapAttrs (
        name: value:
        lib.mkMerge [
          {
            initialize = true;
            repository = "s3:https://s3.eu-central-003.backblazeb2.com/stork-atlas/${name}";
            environmentFile = config.sops.templates."restic/environment".path;
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
          lib.mkIf (value.conflictingService != null) {
            unitConfig.Conflicts = [ value.conflictingService ];
            after = [ value.conflictingService ];
            onSuccess = [ value.conflictingService ];
            onFailure = [ value.conflictingService ];
          }
        )
      );
  };
}
