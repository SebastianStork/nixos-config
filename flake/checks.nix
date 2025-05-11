{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        # statix = pkgs.runCommandLocal "statix" { buildInputs = [ pkgs.statix ]; } ''
        #   statix check ${self}
        #   mkdir $out
        # '';

        deadnix = pkgs.runCommandLocal "deadnix" { buildInputs = [ pkgs.deadnix ]; } ''
          deadnix --fail ${self}
          mkdir $out
        '';
      };
    };

  flake.checks = builtins.mapAttrs (
    _: deployLib: deployLib.deployChecks self.deploy
  ) inputs.deploy-rs.lib;
}
