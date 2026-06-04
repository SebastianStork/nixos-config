{ self, lib, ... }:
let
  mkProfile = name: {
    name = "${name |> lib.removeSuffix ".nix"}-profile";
    value = "${self}/profiles/${name}";
  };
in
{
  flake.nixosModules =
    "${self}/profiles"
    |> lib.readDir
    |> lib.attrNames
    |> self.lib.genAttrs' mkProfile;
}
