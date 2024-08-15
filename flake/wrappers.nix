{
  flake.wrappers.default =
    {
      inputs,
      self,
      pkgs,
      lib,
      ...
    }:
    {
      _module.args.wrappers = lib.mapAttrs' (
        name: _:
        lib.nameValuePair (lib.removeSuffix ".nix" name) (
          import "${self}/wrappers/${name}" { inherit inputs pkgs lib; }
        )
      ) (builtins.readDir "${self}/wrappers");
    };
}
