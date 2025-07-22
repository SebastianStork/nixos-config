{ self, lib, ... }:
let
  modulesOf = dir: dir |> lib.filesystem.listFilesRecursive |> lib.filter (lib.hasSuffix ".nix");
in
{
  flake = {
    nixosModules.default.imports = modulesOf "${self}/modules/system";
    homeManagerModules.default.imports = modulesOf "${self}/modules/home";
  };
}
