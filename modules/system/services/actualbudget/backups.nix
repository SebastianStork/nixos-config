{ config, lib, ... }:
let
  user = config.users.users.actual.name;
in
{
  options.custom.services.actualbudget.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.actualbudget.backups.enable {
    custom.services.resticBackups.actual = {
      inherit user;
      dependentService = "actual.service";
      extraConfig.paths = [ config.services.actual.settings.dataDir ];
    };
  };
}
