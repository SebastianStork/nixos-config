{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        # Disable until https://github.com/oppiliappan/statix/issues/88 is resolved
        # statix = pkgs.runCommandLocal "statix" { buildInputs = [ pkgs.statix ]; } ''
        #   statix check ${self}
        #   mkdir $out
        # '';

        deadnix = pkgs.runCommandLocal "deadnix" { buildInputs = [ pkgs.deadnix ]; } ''
          deadnix --fail ${self}
          mkdir $out
        '';

        flake-checker = pkgs.runCommandLocal "flake-checker" { buildInputs = [ pkgs.flake-checker ]; } ''
          flake-checker --fail-mode
          mkdir $out
        '';
      };
    };

  flake.checks = builtins.mapAttrs (
    _: deployLib: deployLib.deployChecks self.deploy
  ) inputs.deploy-rs.lib;
}
