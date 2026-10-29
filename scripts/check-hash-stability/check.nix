{ flake }:
let
  inherit (flake.inputs.nixpkgs) lib;

  mkSource =
    suffix:
    builtins.path {
      path = flake.outPath;
      name = "check-hash-stability-${suffix}";
    };

  mkSyntheticFlake =
    source:
    let
      syntheticFlake =
        ((import "${source}/flake.nix").outputs (flake.inputs // { self = syntheticFlake; }))
        // {
          _type = "flake";
          inherit (flake) inputs;
          outPath = source;
        };
    in
    syntheticFlake;

  mkHostDrvs =
    syntheticFlake:
    syntheticFlake.nixosConfigurations
    |> lib.mapAttrs (_: host: host.config.system.build.toplevel.drvPath);

  unstableHosts =
    [
      "a"
      "b"
    ]
    |> lib.map mkSource
    |> lib.map mkSyntheticFlake
    |> lib.map mkHostDrvs
    |> lib.zipAttrsWith (_: drvs: (lib.elemAt drvs 0) != (lib.elemAt drvs 1))
    |> lib.filterAttrs (_: changed: changed)
    |> lib.attrNames;
in
if unstableHosts == [ ] then
  true
else
  throw ''
    hash stability regression: host derivations changed when only the flake source store path changed

    unstable hosts:
    ${unstableHosts |> lib.map (host: "- ${host}") |> lib.concatLines}
  ''
