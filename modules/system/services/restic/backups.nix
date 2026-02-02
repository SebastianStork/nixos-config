{ config, lib, ... }:
let
  backups =
    config.custom.services.restic.backups |> lib.attrValues |> lib.filter (backup: backup.enable);
in
{
  options.custom.services.restic.backups = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            enable = lib.mkEnableOption "" // {
              default = true;
            };
            name = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = name;
            };
            conflictingService = lib.mkOption {
              type = lib.types.nullOr lib.types.nonEmptyStr;
              default = null;
            };
            paths = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
            };
            extraConfig = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
            };
          };
        }
      )
    );
    default = { };
  };

  config = lib.mkIf (backups != [ ]) {
    sops = {
      secrets = {
        "backblaze/key-id" = { };
        "backblaze/application-key" = { };
        "restic/password" = { };
      };

      templates."restic/environment".content = ''
        AWS_ACCESS_KEY_ID=${config.sops.placeholder."backblaze/key-id"}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."backblaze/application-key"}
      '';
    };

    systemd.tmpfiles.rules =
      backups |> lib.map (backup: "d /var/cache/restic-backups-${backup.name} 700 - - -");

    services.restic.backups =
      backups
      |> lib.map (backup: {
        inherit (backup) name;
        value = lib.mkMerge [
          {
            inherit (backup) paths;
            initialize = true;
            repository = "s3:https://s3.eu-central-003.backblazeb2.com/stork-atlas/${backup.name}";
            environmentFile = config.sops.templates."restic/environment".path;
            passwordFile = config.sops.secrets."restic/password".path;
            pruneOpts = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 6"
            ];
            timerConfig = {
              OnCalendar = "03:00";
              RandomizedDelaySec = "1h";
            };
          }
          backup.extraConfig
        ];
      })
      |> lib.listToAttrs;

    systemd.services =
      backups
      |> lib.filter (backup: backup.conflictingService != null)
      |> lib.map (backup: {
        name = "restic-backups-${backup.name}";
        value = {
          unitConfig.Conflicts = [ backup.conflictingService ];
          after = [ backup.conflictingService ];
          onSuccess = [ backup.conflictingService ];
          onFailure = [ backup.conflictingService ];
        };
      })
      |> lib.listToAttrs;
  };
}
