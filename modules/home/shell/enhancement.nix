{
    config,
    pkgs,
    lib,
    ...
}: {
    options.myConfig.shell.enhancement.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.shell.enhancement.enable {
        programs.lsd = {
            enable = true;
            enableAliases = true;
        };

        home.shellAliases.cat = let
            theme =
                {
                    dark = "";
                    light = "GitHub";
                }
                ."${config.myConfig.de.theme}";
        in "${lib.getExe pkgs.bat} --plain --theme=${theme}";

        programs.fzf.enable = true;

        programs.zoxide = {
            enable = true;
            options = ["--cmd cd"];
        };
    };
}
