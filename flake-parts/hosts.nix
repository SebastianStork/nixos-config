{
  inputs,
  self,
  lib,
  ...
}:
let
  mkHost =
    baseDir: hostName:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs self;
        inherit (self) allHosts;
      };
      modules =
        lib.singleton { networking.hostName = hostName; }
        ++ self.lib.listNixFilesRecursively "${baseDir}/${hostName}";
    };

  mkHosts = baseDir: baseDir |> self.lib.listDirectoryNames |> self.lib.genAttrs (mkHost baseDir);
in
{
  flake = {
    nixosConfigurations = mkHosts "${self}/hosts/nixos";
    externalConfigurations = mkHosts "${self}/hosts/external";
    allHosts = self.nixosConfigurations // self.externalConfigurations;
  };
}
