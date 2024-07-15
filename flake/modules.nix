{ self, ... }:
let
  modulesOf = dir: map (name: "${dir}/${name}") (builtins.attrNames (builtins.readDir dir));
in
{
  flake.nixosModules = {
    system.imports = modulesOf "${self}/modules/system";
    home.imports = modulesOf "${self}/modules/home";
  };
}
