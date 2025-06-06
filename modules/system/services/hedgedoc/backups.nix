{
  config,
  pkgs,
  lib,
  ...
}:
let
  user = config.users.users.hedgedoc.name;
in
{
  options.custom.services.hedgedoc.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.hedgedoc.backups.enable {
    custom.services.resticBackups.hedgedoc = {
      inherit user;
      suspendService = "hedgedoc.service";
      extraConfig.paths = with config.services.hedgedoc.settings; [
        uploadsPath
        db.storage
      ];
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "hedgedoc-restore";
        text = ''
          sudo --user=${user} bash -c "
            systemctl stop hedgedoc.service
            restic-hedgedoc restore latest --target /
            systemctl start hedgedoc.service
          "
        '';
      })
    ];
  };
}
