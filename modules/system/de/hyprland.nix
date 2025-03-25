{
  config,
  pkgs-unstable,
  lib,
  ...
}:
{
  options.myConfig.de.hyprland.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.hyprland.enable {
    programs.hyprland = {
      enable = true;
      package = pkgs-unstable.hyprland;
      portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
    };

    hardware.graphics = {
      package = pkgs-unstable.mesa;
      package32 = pkgs-unstable.pkgsi686Linux.mesa;
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    services.gvfs.enable = true;
  };
}
