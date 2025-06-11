{ config, lib, ... }:
{
  options.custom.services.hedgedoc.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.hedgedoc.backups.enable {
    custom.services.resticBackups.hedgedoc = {
      dependentService = "hedgedoc.service";
      extraConfig.paths = with config.services.hedgedoc.settings; [
        uploadsPath
        db.storage
      ];
    };
  };
}
