{ config, lib, ... }:
{
  options.custom.services.forgejo.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.forgejo.backups.enable {
    custom.services.resticBackups.forgejo = {
      conflictingService = "forgejo.service";
      extraConfig.paths = [ config.services.forgejo.stateDir ];
    };
  };
}
