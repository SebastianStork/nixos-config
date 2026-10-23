{
  inputs,
  self,
  lib,
  ...
}:
{
  perSystem =
    { self', pkgs, ... }:
    let
      nebulaHostsJson =
        self.allHosts
        |> lib.attrValues
        |> lib.filter (host: host.config.custom.networking.overlay.enable)
        |> lib.map self.lib.nebulaHostInventory
        |> lib.toJSON
        |> pkgs.writeText "nebula-hosts.json";

      unstableHosts =
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
        |> lib.attrNames;
    in
    {
      checks = {
        nebula-certs =
          pkgs.runCommand "nebula-certs" { buildInputs = [ self'.packages.nebula-check-certs ]; } ''
            nebula-check-certs ${nebulaHostsJson}
            touch $out
          ''
          // {
            runsOn = [ "ci" ];
            cache = false;
          };

        nebula-certs-expiry =
          pkgs.runCommand "nebula-certs-expiry" { buildInputs = [ self'.packages.nebula-check-certs ]; } ''
            nebula-check-certs --valid-for 720h ${nebulaHostsJson}
            touch $out
          ''
          // {
            runsOn = [ "schedule" ];
            cache = false;
          };

        hash-stability =
          let
            drv =
              if unstableHosts == [ ] then
                pkgs.runCommand "hash-stability" { } "touch $out"
              else
                throw ''
                  hash stability regression: host derivations changed when only the flake source store path changed

                  unstable hosts:
                  ${unstableHosts |> lib.map (host: "- ${host}") |> lib.concatLines}
                '';
          in
          lib.lazyDerivation {
            derivation = drv;
            passthru = {
              name = "hash-stability";
              runsOn = [ "schedule" ];
              cache = false;
            };
          };
      };
    };
}
