{ self, ... }:
{
  perSystem =
    { self', pkgs, ... }:
    let
      callScript = pkgs.newScope { inherit self'; };

      mkScript = name: {
        inherit name;
        value = callScript "${self}/scripts/${name}" { };
      };
    in
    {
      packages = "${self}/scripts" |> self.lib.listDirectoryNames |> self.lib.genAttrs' mkScript;
    };
}
