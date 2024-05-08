{
    inputs,
    pkgs,
    lib,
    ...
}: let
    assembleWrapper = wrapperConfig:
        (inputs.wrapper-manager.lib {
            inherit pkgs;
            modules = [{wrappers.wrappedPackage = wrapperConfig;}];
        })
        .config
        .wrappers
        .wrappedPackage
        .wrapped;
in {
    _module.args.myWrappers = lib.pipe (builtins.readDir ./.) [
        (lib.filterAttrs (name: value: value == "regular"))
        (lib.filterAttrs (name: value: name != "default.nix"))
        (lib.concatMapAttrs (name: _: {${lib.removeSuffix ".nix" name} = import ./${name} {inherit assembleWrapper pkgs lib;};}))
    ];
}
