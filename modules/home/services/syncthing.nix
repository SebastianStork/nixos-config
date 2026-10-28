{ config, lib, ... }:
{
  options.custom.services.syncthing = {
    tray.enable = lib.mkEnableOption "";
    folders = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
    };
  };

  config = lib.mkIf config.custom.services.syncthing.tray.enable {
    services.syncthing.tray.enable = true;
  };
}
