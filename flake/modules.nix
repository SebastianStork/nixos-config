{ self, ... }:
let
  modulesOf = dir: map (name: "${dir}/${name}") (builtins.attrNames (builtins.readDir dir));
in
{
  flake = {
    nixosModules.default.imports = modulesOf "${self}/modules/system";
    homeManagerModules.default.imports = modulesOf "${self}/modules/home";
  };
}
