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
    _module.args.myWrappers = {
        spotify = import ./spotify.nix {inherit assembleWrapper pkgs lib;};
        obsidian = import ./obsidian.nix {inherit assembleWrapper pkgs lib;};
        marktext = import ./marktext.nix {inherit assembleWrapper pkgs lib;};
    };
}
