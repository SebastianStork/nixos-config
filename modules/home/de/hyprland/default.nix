{
  config,
  pkgs,
  lib,
  ...
}@moduleArgs:
{
  options.custom.de.hyprland.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.custom.de.hyprland.enable or false;
  };

  config = lib.mkIf config.custom.de.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
    };

    home.packages = [
      pkgs.playerctl
      pkgs.grimblast
    ];

    custom = {
      services = {
        wpaperd.enable = true;
        hypridle.enable = true;
        waybar.enable = true;
        cliphist.enable = true;
      };

      programs = {
        rofi.enable = true;
        hyprlock.enable = true;
        btop.enable = true;
      };
    };

    services.dunst.enable = true;
  };
}
