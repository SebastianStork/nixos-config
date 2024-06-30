{ pkgs, ... }:
{
  imports = [ ./default.nix ];

  home-manager.users.seb = {
    home.stateVersion = "23.11";
    myConfig.theme = "dark";

    home.packages = [
      pkgs.ffmpeg
      pkgs.obs-studio
      pkgs.davinci-resolve
      pkgs.gimp
    ];

    wayland.windowManager.hyprland.settings.monitor = [
      "Unknown-1,disable"
      "DP-1,2560x1440@144,0x0,1"
      "HDMI-A-1,2560x1440@60,-1440x-617,1,transform,1"
    ];
  };
}
