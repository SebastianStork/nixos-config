{ config, lib, ... }:
let
  user = config.users.users.hedgedoc.name;
in
{
  options.custom.services.hedgedoc.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.hedgedoc.backups.enable {
    custom.services.resticBackups.hedgedoc = {
      inherit user;
      dependentService = "hedgedoc.service";
      extraConfig.paths = with config.services.hedgedoc.settings; [
        uploadsPath
        db.storage
      ];
    };
  };
}
