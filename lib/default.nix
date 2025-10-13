lib: {
  isTailscaleDomain = domain: domain |> lib.hasSuffix ".ts.net";

  subdomainOf = domain: domain |> lib.splitString "." |> lib.head;

  rootDomainOf = domain: domain |> lib.splitString "." |> lib.tail |> lib.concatStringsSep ".";

  listNixFilesRecursive =
    dir: dir |> lib.filesystem.listFilesRecursive |> lib.filter (lib.hasSuffix ".nix");

  listDirectories =
    path: path |> builtins.readDir |> lib.filterAttrs (_: type: type == "directory") |> lib.attrNames;

  genAttrs = f: names: lib.genAttrs names f;
}
