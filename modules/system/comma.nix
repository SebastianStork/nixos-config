{
    inputs,
    config,
    lib,
    ...
}: {
    imports = [inputs.nix-index-database.nixosModules.nix-index];

    options.myConfig.comma.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.comma.enable {
        programs.command-not-found.enable = false;
        programs.nix-index.enable = true;
        programs.nix-index-database.comma.enable = true;
    };
}
