{ wrappers, ... }:
{
  imports = [ ./default.nix ];

  home-manager.users.seb = {
    home.packages = [ (wrappers.hypridle { lockOnSleep = true; }) ];

    myConfig.de.theme = "light";

    wayland.windowManager.hyprland.settings.monitor = "eDP-1,1920x1080@60,0x0,1";
  };
}
