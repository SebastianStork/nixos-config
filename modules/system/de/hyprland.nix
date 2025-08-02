{
  config,
  pkgs-unstable,
  lib,
  ...
}:
{
  options.custom.de.hyprland.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.de.hyprland.enable {
    programs.hyprland = {
      enable = true;
      package = pkgs-unstable.hyprland;
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    services.gvfs.enable = true;
  };
}
