{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.de.hyprland.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.hyprland.enable {
    programs.hyprland.enable = true;

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    services.gvfs.enable = true;
  };
}
