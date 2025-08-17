{
  inputs,
  self,
  pkgs-unstable,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs self pkgs-unstable;
    };
  };
}
