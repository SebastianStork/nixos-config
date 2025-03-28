{ pkgs, ... }:
{
  imports = [
    ../../home-manager.nix
    ../user.nix
  ];

  users.users.seb.shell = pkgs.zsh;
  programs.zsh.enable = true;

  home-manager.users.seb = ./home.nix;
}
