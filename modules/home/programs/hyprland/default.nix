{ config, lib, ... }:
{
  options.custom.programs.hyprland.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      package = null;
      portalPackage = null;
    };
  };
}
