{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      formatter =
        "${self}/treefmt.nix"
        |> inputs.treefmt.lib.evalModule pkgs
        |> (formatter: formatter.config.build.wrapper);
    };
}
