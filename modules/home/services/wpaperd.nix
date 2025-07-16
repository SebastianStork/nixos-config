{ config, lib, ... }:
{
  options.custom.services.wpaperd.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.wpaperd.enable {
    services.wpaperd = {
      enable = true;
      settings.default = {
        path = "${config.xdg.userDirs.pictures}/Wallpapers";
        duration = "30m";
      };
    };
  };
}
