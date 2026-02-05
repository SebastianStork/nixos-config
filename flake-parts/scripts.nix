{ self, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:
    {
      packages =
        "${self}/scripts"
        |> builtins.readDir
        |> lib.attrNames
        |> lib.map (name: name |> lib.removeSuffix ".nix")
        |> self.lib.genAttrs (name: import "${self}/scripts/${name}.nix" { inherit self' pkgs lib; });
    };
}
