{
  imports = [
    ../../home-manager.nix
    ../user.nix
  ];

  home-manager.users.seb = ./home.nix;
}
