{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      formatter =
        (inputs.treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            prettier.enable = true;
            just.enable = true;
          };
        }).config.build.wrapper;
    };
}
