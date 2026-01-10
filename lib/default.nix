{
  lib,
  self,
}:
{
  isTailscaleDomain = domain: domain |> lib.hasSuffix ".ts.net";

  isPrivateDomain =
    domain: domain |> lib.hasSuffix ".splitleaf.de";

  subdomainOf = domain: domain |> lib.splitString "." |> lib.head;

  rootDomainOf = domain: domain |> lib.splitString "." |> lib.tail |> lib.concatStringsSep ".";

  listNixFilesRecursively =
    dir: dir |> lib.filesystem.listFilesRecursive |> lib.filter (lib.hasSuffix ".nix");

  listDirectoryNames =
    path: path |> builtins.readDir |> lib.filterAttrs (_: type: type == "directory") |> lib.attrNames;

  genAttrs = f: names: lib.genAttrs names f;

  mkUnprotectedMessage =
    name: "${name} should only be exposed on private networks; access control isn't yet configured";

  relativePath = path: path |> toString |> lib.removePrefix "${self}/";
}
