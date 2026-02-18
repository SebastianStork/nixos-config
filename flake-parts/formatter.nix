{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      formatter = (inputs.treefmt.lib.evalModule pkgs "${self}/treefmt.nix").config.build.wrapper;
    };
}
