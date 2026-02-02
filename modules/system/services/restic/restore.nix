{
  config,
  pkgs,
  lib,
  ...
}:
let
  backupsWithRestoreCommand =
    config.custom.services.restic.backups
    |> lib.attrValues
    |> lib.filter (backup: backup.enable && backup.restoreCommand.enable);
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
      let
        restoreScripts =
          backupsWithRestoreCommand
          |> lib.map (
            backup:
            let
              inherit (backup) name conflictingService;
              inherit (backup.restoreCommand) preRestore postRestore;
              hasConflictingService = conflictingService != null;
            in
            pkgs.writeShellApplication {
              name = "restic-restore-${name}";
              text = ''
                ${lib.optionalString hasConflictingService "systemctl stop ${conflictingService}"}
                ${preRestore}
                restic-${name} restore latest --target /
                ${postRestore}
                ${lib.optionalString hasConflictingService "systemctl start ${conflictingService}"}
              '';
            }
          );

        restoreAllScript = pkgs.writeShellApplication {
          name = "restic-restore-all";
          text =
            backupsWithRestoreCommand |> lib.map (backup: "restic-restore-${backup.name}") |> lib.concatLines;
        };
      in
      restoreScripts ++ [ restoreAllScript ];
  };
}
