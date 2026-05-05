{ config, lib, ... }:
let
  cfg = config.custom.services.file-share;
in
{
  options.custom.services.file-share = {
    enable = lib.mkEnableOption "";
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    environment.persistence."/persist".users.seb.directories = [ "share" ];

    custom.services.restic.backups.file-share.paths = lib.mkIf cfg.doBackups [ "/home/seb/share" ];
  };
}
