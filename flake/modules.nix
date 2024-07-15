{ self, ... }:
let
  modulesOf = dir: map (name: "${dir}/${name}") (builtins.attrNames (builtins.readDir dir));
in
{
  flake.nixosModules = {
    nixos.imports = modulesOf "${self}/modules/nixos";
    home-manager.imports = modulesOf "${self}/modules/home-manager";
  };
}
