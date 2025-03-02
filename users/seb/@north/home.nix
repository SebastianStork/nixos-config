{ pkgs, ... }:
{
  imports = [ ../home.nix ];

  home.stateVersion = "23.11";

  myConfig = {
    de.theme = "dark";
    hibernation.enable = true;
  };

  home.packages = [
    pkgs.ffmpeg
    pkgs.obs-studio
    pkgs.davinci-resolve
    pkgs.gimp
  ];

  wayland.windowManager.hyprland.settings.monitor = [ "DP-1,2560x1440@144,0x0,1" ];
}
