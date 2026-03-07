{
  config,
  pkgs-unstable,
  lib,
  ...
}:
{
  options.custom.desktop.hyprland.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.desktop.hyprland.enable {
    programs.hyprland = {
      enable = true;
      package = pkgs-unstable.hyprland;
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    services.gvfs.enable = true;
  };
}
