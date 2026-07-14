{
  inputs,
  self,
  lib,
}:
let
  mkSource =
    suffix:
    builtins.path {
      path = self;
      name = "hash-stability-${suffix}";
    };

  inputsWithoutSelf = inputs |> lib.filterAttrs (name: _: name != "self");

  mkSyntheticFlake =
    source:
    let
      flake = ((import "${source}/flake.nix").outputs (inputsWithoutSelf // { self = flake; })) // {
        _type = "flake";
        inputs = inputsWithoutSelf;
        outPath = source;
      };
    in
    flake;

  mkHostDrvs =
    flake:
    flake.nixosConfigurations |> lib.mapAttrs (_: host: host.config.system.build.toplevel.drvPath);
in
[
  "a"
  "b"
]
|> lib.map mkSource
|> lib.map mkSyntheticFlake
|> lib.map mkHostDrvs
|> lib.zipAttrsWith (_: drvs: (lib.elemAt drvs 0) != (lib.elemAt drvs 1))
|> lib.filterAttrs (_: changed: changed)
|> lib.attrNames
