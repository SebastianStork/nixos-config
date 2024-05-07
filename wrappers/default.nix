{
    inputs,
    pkgs,
    lib,
    ...
}: {
    _module.args.myWrappers = {
        spotify = import ./spotify.nix {inherit inputs pkgs lib;};
        obsidian = import ./obsidian.nix {inherit inputs pkgs lib;};
        marktext = import ./marktext.nix {inherit inputs pkgs lib;};
    };
}
