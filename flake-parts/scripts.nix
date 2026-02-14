{ self, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:
    let
      mkScript = file: rec {
        name =
          file
          |> lib.unsafeDiscardStringContext
          |> lib.removePrefix "${self}/scripts/"
          |> lib.removeSuffix ".nix"
          |> lib.replaceString "/" "-";
        value = pkgs.writeShellApplication ({ inherit name; } // import file { inherit self' pkgs lib; });
      };
    in
    {
      packages =
        "${self}/scripts" |> lib.filesystem.listFilesRecursive |> lib.map mkScript |> lib.listToAttrs;
    };
}
