{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      mkTest = name: {
        name = "${name}-test";
        value = pkgs.testers.runNixOSTest {
          inherit name;
          _module.args = { inherit inputs self; };
          imports = [ "${self}/tests/${name}" ];
        };
      };
    in
    {
      checks = "${self}/tests" |> self.lib.listDirectoryNames |> self.lib.genAttrs' mkTest;
    };
}
