{
    inputs,
    config,
    lib,
    ...
}: {
    imports = [inputs.nh.nixosModules.default];

    options.myConfig.nix-helper.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.nix-helper.enable {
        nh.enable = true;
    };
}
