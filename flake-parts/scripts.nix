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
        |> lib.filesystem.listFilesRecursive
        |> lib.map (file: {
          name =
            file
            |> lib.unsafeDiscardStringContext
            |> lib.removePrefix "${self}/scripts/"
            |> lib.removeSuffix ".nix"
            |> lib.replaceString "/" "-";
          value = import file { inherit self' pkgs lib; };
        })
        |> lib.listToAttrs;
    };
}
