{
  inputs,
  self,
  lib,
  ...
}:
let
  mkHost =
    hostDir:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs self;
        inherit (self) allHosts;
      };
      modules =
        (lib.singleton {
          networking.hostName = hostDir |> lib.baseNameOf |> lib.unsafeDiscardStringContext;
        })
        ++ self.lib.listNixFilesRecursively hostDir;
    };

  mkHosts =
    baseDir:
    baseDir
    |> self.lib.listDirectoryNames
    |> self.lib.genAttrs (hostName: mkHost "${baseDir}/${hostName}");
in
{
  flake = {
    nixosConfigurations = mkHosts "${self}/hosts";
    externalConfigurations = mkHosts "${self}/external-hosts";
    allHosts = self.nixosConfigurations // self.externalConfigurations;
  };
}
