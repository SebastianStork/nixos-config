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
      modules = [
        { networking = { inherit hostName; }; }
        "${self}/hosts/${hostName}/default.nix"
        "${self}/hosts/${hostName}/hardware.nix"
        "${self}/hosts/${hostName}/disko.nix"
        "${self}/users/seb"
      ]
      ++ lib.optional (lib.pathExists "${self}/users/seb/@${hostName}") "${self}/users/seb/@${hostName}";
    };
in
{
  flake.nixosConfigurations =
    "${self}/hosts" |> self.lib.listDirectoryNames |> self.lib.genAttrs mkHost;
}
