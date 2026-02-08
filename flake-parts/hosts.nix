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
      specialArgs = { inherit inputs self; };
      modules =
        (lib.singleton {
          networking.hostName = hostDir |> lib.baseNameOf |> lib.unsafeDiscardStringContext;
        })
        ++ (
          hostDir
          |> builtins.readDir
          |> lib.attrNames
          |> lib.filter (lib.hasSuffix ".nix")
          |> lib.map (file: "${hostDir}/${file}")
        );
    };

  mkHosts =
    baseDir:
    baseDir
    |> builtins.readDir
    |> lib.filterAttrs (_: type: type == "directory")
    |> lib.mapAttrs (hostName: _: mkHost "${baseDir}/${hostName}");
in
{
  flake = {
    nixosConfigurations = mkHosts "${self}/hosts";
    externalConfigurations = mkHosts "${self}/external-hosts";
    allHosts = self.nixosConfigurations // self.externalConfigurations;
  };
}
