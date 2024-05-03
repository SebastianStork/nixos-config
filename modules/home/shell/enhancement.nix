{
    config,
    pkgs,
    lib,
    ...
}: {
    options.myConfig.shell.enhancement.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.shell.enhancement.enable {
        programs.fzf.enable = true;

        programs.zoxide = {
            enable = true;
            options = ["--cmd cd"];
        };

        home.shellAliases = let
            lsAliases = let
                listCmd = "${lib.getExe pkgs.eza} --header --group --time-style=long-iso --group-directories-first --sort=name --icons=auto --git --git-repos-no-status --binary";
                aliasList = lib.crossLists (a: b: c: "${a}${b}${c}") [["ll" "lt" "l"] ["" "a"] ["" "d" "f"]];
                convertAliasToCmd = str: "${listCmd} " + (builtins.replaceStrings ["ll" "lt" "l" "a" "d" "f"] ["--long " "--tree " "--oneline --dereference " "--all " "--only-dirs " "--only-files "] str);
                aliasAttrs = lib.genAttrs aliasList convertAliasToCmd;
            in
                aliasAttrs // {ls = "l";};

            catAlias = let
                theme =
                    {
                        dark = "";
                        light = "GitHub";
                    }
                    ."${config.myConfig.de.theme}";
            in {cat = "${lib.getExe pkgs.bat} --plain --theme=${theme}";};
        in
            lib.mkMerge [
                lsAliases
                catAlias
            ];
    };
}
