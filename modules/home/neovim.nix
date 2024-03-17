{
    config,
    lib,
    ...
}: {
    options.myConfig.neovim.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.neovim.enable {
        programs.neovim = {
            enable = true;
            defaultEditor = true;
            viAlias = true;
            vimAlias = true;
            vimdiffAlias = true;
        };
    };
}
