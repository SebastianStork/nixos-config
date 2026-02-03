{ self, ... }:
{
  flake = {
    nixosModules.default.imports = self.lib.listNixFilesRecursively "${self}/modules/system";
    homeModules.default.imports = self.lib.listNixFilesRecursively "${self}/modules/home";
  };
}
