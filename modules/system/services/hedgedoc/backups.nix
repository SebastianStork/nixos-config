{ config, lib, ... }:
{
  options.custom.services.hedgedoc.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.hedgedoc.backups.enable {
    custom.services.resticBackups.hedgedoc = {
      conflictingService = "hedgedoc.service";
      extraConfig.paths = with config.services.hedgedoc.settings; [
        uploadsPath
        db.storage
      ];
    };
  };
}
