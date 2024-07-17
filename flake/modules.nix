{ self, lib, ... }:
let
  modulesOf = dir: builtins.filter (lib.hasSuffix ".nix") (lib.filesystem.listFilesRecursive dir);
in
{
  flake = {
    nixosModules.default.imports = modulesOf "${self}/modules/system";
    homeManagerModules.default.imports = modulesOf "${self}/modules/home";
  };
}
