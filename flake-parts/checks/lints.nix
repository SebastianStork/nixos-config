{
  inputs,
  self,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        formatting = (inputs.treefmt.lib.evalModule pkgs "${self}/treefmt.nix").config.build.check self // {
          runsOn = [ "ci" ];
          cache = false;
        };

        statix =
          pkgs.runCommand "statix" { buildInputs = [ pkgs.statix ]; } ''
            statix check ${self}
            touch $out
          ''
          // {
            runsOn = [ "ci" ];
            cache = false;
          };

        deadnix =
          pkgs.runCommand "deadnix" { buildInputs = [ pkgs.deadnix ]; } ''
            deadnix --fail ${self}
            touch $out
          ''
          // {
            runsOn = [ "ci" ];
            cache = false;
          };
      };
    };
}
