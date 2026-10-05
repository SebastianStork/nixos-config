{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.hyprland.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.hyprland.enable {
    home.packages = [
      pkgs.grim
      pkgs.jq
      pkgs.satty
      pkgs.slurp
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      package = null;
      portalPackage = null;
    };
  };
}
