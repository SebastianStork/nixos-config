{ inputs, self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      mkTest = dir: rec {
        name = "${dir}-test";
        value = pkgs.testers.runNixOSTest (
          {
            inherit name;
          }
          // import "${self}/tests/${dir}" {
            inherit
              inputs
              self
              pkgs
              lib
              ;
          }
        );
      };
    in
    {
      checks = "${self}/tests" |> builtins.readDir |> lib.attrNames |> lib.map mkTest |> lib.listToAttrs;
    };
}
