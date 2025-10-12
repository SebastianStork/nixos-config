lib: {
  isTailscaleDomain = domain: domain |> lib.hasSuffix ".ts.net";

  subdomainOf = domain: domain |> lib.splitString "." |> lib.head;

  rootDomainOf = domain: domain |> lib.splitString "." |> lib.tail |> lib.concatStringsSep ".";
}
