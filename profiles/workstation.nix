{
  config,
  inputs,
  self,
  pkgs,
  pkgs-unstable,
  allHosts,
  ...
}:
{
  imports = [
    self.nixosModules.core-profile
    inputs.home-manager.nixosModules.home-manager
  ];

  boot.kernelPackages = pkgs.linuxPackages_6_19;

  custom = {
    networking.overlay.role = "client";
    boot.silent = true;
    login.tuigreet = {
      enable = true;
      autoLogin = true;
    };
    desktop.hyprland.enable = true;
    services = {
      sound.enable = true;
      syncthing.enable = true;
      alloy.enable = true;
    };
  };

  programs.localsend.enable = true;

  programs.zsh.enable = true;
  users.users.seb.shell = pkgs.zsh;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit
        inputs
        self
        pkgs-unstable
        allHosts
        ;
    };
    users.seb.imports = [
      "${self}/users/seb/home.nix"
      "${self}/users/seb/@${config.networking.hostName}/home.nix"
    ];
  };
}
