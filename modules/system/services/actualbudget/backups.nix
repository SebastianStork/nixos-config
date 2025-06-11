{ config, lib, ... }:
{
  options.custom.services.actualbudget.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.actualbudget.backups.enable {
    custom.services.resticBackups.actual = {
      dependentService = "actual.service";
      extraConfig.paths = [ config.services.actual.settings.dataDir ];
    };
  };
}
