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
      _module.args.wrappers = lib.concatMapAttrs (name: _: {
        ${lib.removeSuffix ".nix" name} = import "${self}/wrappers/${name}" { inherit inputs pkgs lib; };
      }) (builtins.readDir "${self}/wrappers");
    };
}
