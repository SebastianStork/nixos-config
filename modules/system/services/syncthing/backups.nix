{ config, lib, ... }:
let
  cfg = config.custom.services.syncthing;

  user = config.users.users.syncthing.name;
in
{
  options.custom.services.syncthing.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.backups.enable {
    assertions = [
      {
        assertion = cfg.isServer;
        message = "syncthing backups can only be made on a server";
      }
    ];

    custom.services.resticBackups.syncthing = {
      inherit user;
      dependentService = "syncthing.service";
      extraConfig.paths = [ config.services.syncthing.dataDir ];
    };
  };
}
