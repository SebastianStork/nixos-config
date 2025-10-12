{ self, lib, ... }:
let
  listNixFilesRecursive =
    dir: dir |> lib.filesystem.listFilesRecursive |> lib.filter (lib.hasSuffix ".nix");
in
{
  flake = {
    nixosModules.default.imports = listNixFilesRecursive "${self}/modules/system";
    homeManagerModules.default.imports = listNixFilesRecursive "${self}/modules/home";
  };
}
