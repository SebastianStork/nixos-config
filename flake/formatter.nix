{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      formatter =
        (inputs.treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
          programs.prettier.enable = true;
        }).config.build.wrapper;
    };
}
