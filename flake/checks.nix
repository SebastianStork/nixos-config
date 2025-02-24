{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        statix = pkgs.runCommand "statix" { buildInputs = [ pkgs.statix ]; } ''
          statix check ${self}
          mkdir $out
        '';

        deadnix = pkgs.runCommand "deadnix" { buildInputs = [ pkgs.deadnix ]; } ''
          deadnix ${self} --fail --exclude ${self}/flake/formatter.nix
          mkdir $out
        '';
      };
    };

  flake.checks = builtins.mapAttrs (
    _: deployLib: deployLib.deployChecks self.deploy
  ) inputs.deploy-rs.lib;
}
