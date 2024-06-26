{ wrappers, ... }:
{
  imports = [ ./default.nix ];

  home-manager.users.seb = {
    home.stateVersion = "23.11";
    myConfig.theme = "light";
    home.packages = [ wrappers.hyprlock ];
  };
}
