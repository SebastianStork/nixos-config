{ inputs, self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      checks =
        "${self}/tests"
        |> builtins.readDir
        |> lib.attrNames
        |> lib.map (name: {
          name = "${name}-test";
          value = pkgs.testers.runNixOSTest (
            {
              name = "${name}-test";
            }
            // import "${self}/tests/${name}" {
              inherit
                inputs
                self
                pkgs
                lib
                ;
            }
          );
        })
        |> lib.listToAttrs;
    };
}
