{ wrappers, ... }:
{
  imports = [ ./default.nix ];

  home-manager.users.seb = {
    home.packages = [ (wrappers.hypridle { lockOnSleep = true; }) ];

    myConfig.de.theme = "light";
  };
}
