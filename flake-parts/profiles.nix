{ self, lib, ... }:
{
  flake.nixosModules =
    "${self}/profiles"
    |> lib.readDir
    |> lib.attrNames
    |> lib.map (name: {
      name = "${name |> lib.removeSuffix ".nix"}-profile";
      value = "${self}/profiles/${name}";
    })
    |> lib.listToAttrs;
}
