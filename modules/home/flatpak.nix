{ config, lib, ... }@moduleArgs:
{
  options.myConfig.flatpak.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.myConfig.flatpak.enable or false;
  };

  config = lib.mkIf config.myConfig.flatpak.enable {
    xdg = {
      enable = true;
      systemDirs.data = [
        "/var/lib/flatpak/exports/share"
        "/home/seb/.local/share/flatpak/exports/share"
      ];
    };
  };
}
