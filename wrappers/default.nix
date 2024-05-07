{
    inputs,
    pkgs,
    lib,
    ...
}: let
    assembleWrapper = wrapperName: wrapperConfig:
        (inputs.wrapper-manager.lib {
            inherit pkgs;
            modules = [{wrappers.${wrapperName} = wrapperConfig;}];
        })
        .config
        .wrappers
        .${wrapperName}
        .wrapped;
in {
    _module.args.myWrappers = lib.pipe (builtins.readDir ./.) [
        (lib.filterAttrs (name: value: value == "regular"))
        (lib.filterAttrs (name: value: name != "default.nix"))
        (lib.concatMapAttrs (name: _: {${lib.removeSuffix ".nix" name} = import ./${name} {inherit assembleWrapper pkgs lib;};}))
    ];
}
