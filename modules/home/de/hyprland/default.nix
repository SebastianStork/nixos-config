{
  config,
  inputs,
  pkgs,
  lib,
  ...
}@moduleArgs:
{
  # Use unstable hyprland module for nullable package
  disabledModules = [ "services/window-managers/hyprland.nix" ];
  imports = [ "${inputs.home-manager-unstable}/modules/services/window-managers/hyprland.nix" ];

  options.myConfig.de.hyprland.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.myConfig.de.hyprland.enable or false;
  };

  config = lib.mkIf config.myConfig.de.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
    };

    home.packages = [
      pkgs.playerctl
      pkgs.grimblast
    ];

    myConfig.deUtils = {
      rofi.enable = true;
      hyprpaper.enable = true;
      hyprlock.enable = true;
      hypridle.enable = true;
      waybar.enable = true;
      cliphist.enable = true;
      gammastep.enable = true;
    };

    services.dunst.enable = true;
  };
}
