{
  inputs,
  pkgs,
  lib,
  ...
}@moduleArgs:
let
  assembleWrapper =
    wrapperConfig:
    (inputs.wrapper-manager.lib {
      inherit pkgs;
      modules = [ { wrappers.wrappedPackage = wrapperConfig; } ];
    }).config.wrappers.wrappedPackage.wrapped;
in
{
  _module.args.wrappers = lib.pipe (builtins.readDir ./.) [
    (lib.filterAttrs (name: _: name != "default.nix"))
    (lib.concatMapAttrs (
      name: _: {
        ${lib.removeSuffix ".nix" name} = import ./${name} { inherit assembleWrapper moduleArgs; };
      }
    ))
  ];
}
