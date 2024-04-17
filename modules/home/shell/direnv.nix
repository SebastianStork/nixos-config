{
    config,
    lib,
    ...
}: {
    options.myConfig.shell.direnv.enable = lib.mkEnableOption "";

    config.programs.direnv = lib.mkIf config.myConfig.shell.direnv.enable {
        enable = true;
        nix-direnv.enable = true;
        config.global.hide_env_diff = true;
    };
}
