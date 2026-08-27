{
  inputs,
  self,
  lib,
  withSystem,
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
        lib.singleton (
          { config, ... }:
          let
            configuredPkgs = withSystem config.nixpkgs.hostPlatform.system;
          in
          {
            networking.hostName = hostName;
            nixpkgs.pkgs = configuredPkgs ({ pkgs, ... }: pkgs);
            _module.args.pkgs-unstable = configuredPkgs ({ pkgs-unstable, ... }: pkgs-unstable);
          }
        )
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
