{ self, pkgs, ... }:
{
  imports = [
    ../user.nix
    "${self}/users/home-manager.nix"
  ];

  users.users.seb.shell = pkgs.zsh;
  programs.zsh.enable = true;

  home-manager.users.seb = ./home.nix;
}
