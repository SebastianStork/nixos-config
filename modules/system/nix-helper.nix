{
    inputs,
    config,
    lib,
    ...
}: {
    imports = [inputs.nh.nixosModules.default];

    options.myConfig.nix-helper.enable = lib.mkEnableOption "";

    config.nh.enable = config.myConfig.nix-helper.enable;
}
