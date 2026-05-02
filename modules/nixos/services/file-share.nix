{ config, lib, ... }:
let
  cfg = config.custom.services.file-share;
  shareDir = "/home/seb/share";
in
{
  options.custom.services.file-share = {
    enable = lib.mkEnableOption "";
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.tmpfiles.users."seb".rules = [ "d ${shareDir} - - - -" ];

    custom = {
      services.restic.backups.filebrowser.paths = lib.mkIf cfg.doBackups [ shareDir ];

      persistence.directories = [ shareDir ];
    };
  };
}
