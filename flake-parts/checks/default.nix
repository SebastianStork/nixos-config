{ self, lib, ... }:
{
  imports = [
    ./invariants.nix
    ./lints.nix
    ./tests.nix
  ];

  perSystem = {
    checks =
      self.nixosConfigurations
      |> lib.mapAttrs (
        _: host:
        host.config.system.build.toplevel
        // {
          runsOn = [ "ci" ];
          cache = true;
        }
      );
  };
}
