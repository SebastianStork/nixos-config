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
        "${self}/hosts/common.nix"
        "${self}/hosts/${hostName}"
        "${self}/users/seb"
      ]
      ++ lib.optional (lib.pathExists "${self}/users/seb/@${hostName}") "${self}/users/seb/@${hostName}";
    };
in
{
  flake.nixosConfigurations =
    "${self}/hosts" |> self.lib.listDirectoryNames |> self.lib.genAttrs mkHost;
}
