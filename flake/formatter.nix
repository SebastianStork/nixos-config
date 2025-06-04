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
          settings.formatter.nixfmt.excludes = [ "modules/home/programs/shell/aliases.nix" ];
        }).config.build.wrapper;
    };
}
