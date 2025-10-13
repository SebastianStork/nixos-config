{ self, inputs, ... }:
let
  lib = inputs.nixpkgs.lib.extend (_: _: { custom = import "${self}/lib" inputs.nixpkgs.lib; });
in
{
  flake = {
    nixosModules.default.imports = lib.custom.listNixFilesRecursive "${self}/modules/system";
    homeManagerModules.default.imports = lib.custom.listNixFilesRecursive "${self}/modules/home";
  };
}
