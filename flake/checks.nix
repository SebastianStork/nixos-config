{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        treefmt = (import ./treefmt.nix { inherit inputs pkgs; }).check self;

        statix =
          let
            statix-config = pkgs.writeText "statix.toml" ''
              disabled = ["repeated_keys"]
            '';
          in
          pkgs.runCommand "statix" { buildInputs = [ pkgs.statix ]; } ''
            statix check ${self} --config ${statix-config}
            mkdir $out
          '';

        deadnix = pkgs.runCommand "deadnix" { buildInputs = [ pkgs.deadnix ]; } ''
          deadnix ${self} --fail --exclude ${self}/flake/formatter.nix
          mkdir $out
        '';
      };
    };
}
