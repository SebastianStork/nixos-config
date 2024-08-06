{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        treefmt = (import ./treefmt.nix { inherit inputs pkgs; }).check self;

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
}
