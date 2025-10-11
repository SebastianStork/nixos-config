{ self, pkgs, ... }:
{
  imports = [ "${self}/users/home-manager.nix" ];
  home-manager.users.seb = ./home.nix;

  users.users.seb.shell = pkgs.zsh;
  programs.zsh.enable = true;
}
