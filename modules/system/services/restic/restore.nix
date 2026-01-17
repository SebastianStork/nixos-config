{
  config,
  pkgs,
  lib,
  ...
}:
let
  backupsWithRestoreCommand =
    config.custom.services.restic.backups
    |> lib.filterAttrs (_: backup: backup.enable && backup.restoreCommand.enable);
in
{
  options.custom.services.restic.backups = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.restoreCommand = {
          enable = lib.mkEnableOption "" // {
            default = true;
          };
          preRestore = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          postRestore = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
        };
      }
    );
  };

  config = {
    environment.systemPackages =
      backupsWithRestoreCommand
      |> lib.mapAttrsToList (
        name: backup:
        pkgs.writeShellApplication {
          name = "restic-restore-${name}";
          text =
            let
              inherit (backup) conflictingService;
              inherit (backup.restoreCommand) preRestore postRestore;
              hasConflictingService = conflictingService != null;
            in
            ''
              ${lib.optionalString hasConflictingService "systemctl stop ${conflictingService}"}
              ${preRestore}
              restic-${name} restore latest --target /
              ${postRestore}
              ${lib.optionalString hasConflictingService "systemctl start ${conflictingService}"}
            '';
        }
      );
  };
}
