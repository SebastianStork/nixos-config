{
  config,
  inputs,
  self,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  imports = [
    self.nixosModules.profile-core
    inputs.home-manager.nixosModules.home-manager
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  custom = {
    networking.overlay.role = "client";
    boot.silent = true;
    dm.tuigreet = {
      enable = true;
      autoLogin = true;
    };
    de.hyprland.enable = true;
    services = {
      sound.enable = true;
      syncthing.enable = true;
    };
  };

  programs.localsend.enable = true;

  programs.zsh.enable = true;
  users.users.seb.shell = pkgs.zsh;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs self pkgs-unstable; };
    users.seb = "${self}/users/seb/@${config.networking.hostName}/home.nix";
  };
}
