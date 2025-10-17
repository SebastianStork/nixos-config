{ self, ... }:
{
  flake = {
    nixosModules.default.imports = self.lib.listNixFilesRecursive "${self}/modules/system";
    homeManagerModules.default.imports = self.lib.listNixFilesRecursive "${self}/modules/home";
  };
}
