{ inputs, self, ... }:
{
  perSystem =
    { inputs', pkgs, ... }:
    {
      checks = {
        formatting =
          "${self}/treefmt.nix"
          |> inputs.treefmt.lib.evalModule pkgs
          |> (formatter: formatter.config.build.check self);

        statix = pkgs.runCommand "statix" { buildInputs = [ inputs'.statix.packages.statix ]; } ''
          statix check ${self}
          touch $out
        '';

        deadnix = pkgs.runCommand "deadnix" { buildInputs = [ pkgs.deadnix ]; } ''
          deadnix --fail ${self}
          touch $out
        '';
      };
    };
}
