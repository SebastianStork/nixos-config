{ self, ... }:
{
  flake = {
    nixosModules.default.imports = self.lib.listNixFilesRecursively "${self}/modules/nixos";
    homeModules.default.imports = self.lib.listNixFilesRecursively "${self}/modules/home";
  };
}
