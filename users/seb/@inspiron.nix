{ wrappers, ... }:
{
  imports = [ ./default.nix ];

  home-manager.users.seb = {
    home.packages = [ wrappers.hyprlock ];

    myConfig.theme = "light";
  };
}
