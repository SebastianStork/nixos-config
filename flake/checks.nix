{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        # Ignore hosts.nix until https://github.com/oppiliappan/statix/issues/88 is resolved
        statix = pkgs.runCommand "statix" { buildInputs = [ pkgs.statix ]; } ''
          statix check --ignore ${self}/flake/hosts.nix ${self}
          mkdir $out
        '';

        deadnix = pkgs.runCommand "deadnix" { buildInputs = [ pkgs.deadnix ]; } ''
          deadnix --fail ${self}
          mkdir $out
        '';

        flake-checker = pkgs.runCommand "flake-checker" { buildInputs = [ pkgs.flake-checker ]; } ''
          flake-checker --fail-mode
          mkdir $out
        '';
      };
    };

  flake.checks = builtins.mapAttrs (
    _: deployLib: deployLib.deployChecks self.deploy
  ) inputs.deploy-rs.lib;
}
