{ pkgs, wrappers, ... }:
{
  imports = [ ./default.nix ];

  home-manager.users.seb = {
    home.packages = [
      pkgs.obs-studio
      pkgs.libsForQt5.kdenlive
      pkgs.gimp

      (wrappers.hypridle { lockOnSleep = false; })
    ];

    myConfig.theme = "dark";
  };
}
