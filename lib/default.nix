lib: {
  isTailscaleDomain = domain: domain |> lib.hasSuffix ".ts.net";

  subdomainOf = domain: domain |> lib.splitString "." |> lib.head;

  rootDomainOf = domain: domain |> lib.splitString "." |> lib.tail |> lib.concatStringsSep ".";

  listNixFilesRecursively =
    dir: dir |> lib.filesystem.listFilesRecursive |> lib.filter (lib.hasSuffix ".nix");

  listDirectoryNames =
    path: path |> builtins.readDir |> lib.filterAttrs (_: type: type == "directory") |> lib.attrNames;

  genAttrs = f: names: lib.genAttrs names f;

  mkUnprotectedMessage =
    name: "${name} should only be exposed on private networks; access control isn't yet configured";
}
