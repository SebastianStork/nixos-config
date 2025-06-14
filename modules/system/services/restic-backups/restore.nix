{
  config,
  pkgs,
  lib,
  ...
}:
let
  backupsWithRestoreCommand =
    config.custom.services.resticBackups
    |> lib.filterAttrs (_: value: value.enable)
    |> lib.filterAttrs (_: value: value.restoreCommand.enable);
in
{
  options.custom.services.resticBackups = lib.mkOption {
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
        name: value:
        pkgs.writeShellApplication {
          name = "restic-restore-${name}";
          text =
            let
              inherit (value) conflictingService;
              hasconflictingService = conflictingService != null;
            in
            ''
              ${lib.optionalString hasconflictingService "systemctl stop ${conflictingService}"}
              ${value.restoreCommand.preRestore}
              restic-${name} restore latest --target /
              ${value.restoreCommand.postRestore}
              ${lib.optionalString hasconflictingService "systemctl start ${conflictingService}"}
            '';
        }
      );
  };
}
