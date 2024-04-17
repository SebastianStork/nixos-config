{
    config,
    lib,
    ...
}: {
    options.myConfig.shell.enhancedCommands.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.shell.enhancedCommands.enable {
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
