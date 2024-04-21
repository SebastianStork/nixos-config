{
    config,
    lib,
    ...
}: {
    options.myConfig.shell.enhancement.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.shell.enhancement.enable {
        programs.lsd = {
            enable = true;
            enableAliases = true;
        };

        programs.bat.enable = true;
        home.shellAliases.cat = "bat -p";

        programs.fzf.enable = true;

        programs.zoxide = {
            enable = true;
            options = ["--cmd cd"];
        };
    };
}
