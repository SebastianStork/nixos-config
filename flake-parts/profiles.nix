{ self, lib, ... }:
{
  flake.nixosModules =
    "${self}/profiles"
    |> builtins.readDir
    |> lib.attrNames
    |> lib.map (name: {
      name = "profile-${name |> lib.removeSuffix ".nix"}";
      value = "${self}/profiles/${name}";
    })
    |> lib.listToAttrs;
}
