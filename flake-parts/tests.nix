{
  inputs,
  self,
  lib,
  flake-parts-lib,
  ...
}:
{
  imports = lib.singleton (
    flake-parts-lib.mkTransposedPerSystemModule {
      name = "tests";
      option = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.package;
        default = { };
      };
      file = ./tests.nix;
    }
  );

  perSystem =
    { pkgs, ... }:
    let
      mkTest = name: {
        inherit name;
        value = pkgs.testers.runNixOSTest {
          inherit name;
          _module.args = { inherit inputs self; };
          imports = [ "${self}/tests/${name}" ];
        };
      };
    in
    {
      tests = "${self}/tests" |> self.lib.listDirectoryNames |> self.lib.genAttrs' mkTest;
    };
}
