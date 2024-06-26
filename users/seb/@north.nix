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
  };
}
