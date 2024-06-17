{ pkgs, ... }:
{
  imports = [ ./default.nix ];

  home-manager.users.seb = {
    home.packages = [
      pkgs.ffmpeg
      pkgs.obs-studio
      pkgs.davinci-resolve
      pkgs.gimp
    ];

    myConfig.theme = "dark";
  };
}
