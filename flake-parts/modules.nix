{ self, ... }:
{
  flake = {
    nixosModules.default.imports = self.lib.listNixFilesRecursively "${self}/modules/system";
    homeManagerModules.default.imports = self.lib.listNixFilesRecursively "${self}/modules/home";
  };
}
