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
              inherit (value) dependentService;
              hasDependentService = dependentService != null;
            in
            ''
              ${lib.optionalString hasDependentService "sudo systemctl stop ${dependentService}"}
              sudo --user=${value.user} bash -c "
                ${value.restoreCommand.preRestore}
                restic-${name} restore latest --target /
                ${value.restoreCommand.postRestore}
              "
              ${lib.optionalString hasDependentService "sudo systemctl start ${dependentService}"}
            '';
        }
      );
  };
}
