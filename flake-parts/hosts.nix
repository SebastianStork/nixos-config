{
  inputs,
  self,
  lib,
  ...
}:
let
  mkHost =
    hostName:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs self; };
      modules =
        (lib.singleton { networking = { inherit hostName; }; })
        ++ (
          "${self}/hosts/${hostName}"
          |> builtins.readDir
          |> lib.attrNames
          |> lib.filter (file: file |> lib.hasSuffix ".nix")
          |> lib.map (file: "${self}/hosts/${hostName}/${file}")
        );
    };
in
{
  flake.nixosConfigurations =
    "${self}/hosts" |> self.lib.listDirectoryNames |> self.lib.genAttrs mkHost;
}
