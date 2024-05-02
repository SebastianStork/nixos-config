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
                list = "${lib.getExe pkgs.eza} --header --group --time-style=long-iso --group-directories-first --sort=name --icons=auto --git --git-repos-no-status --binary";

                convertFlagAliasToFlag = char:
                    {
                        a = "--all";
                        d = "--only-dirs";
                        f = "--only-files";
                    }
                    .${char};
                convertFlagAliasesToFlags = str: "${lib.concatStringsSep " " (lib.forEach (lib.stringToCharacters str) convertFlagAliasToFlag)}";
                flagAliasCombos = lib.crossLists (a: b: "${a}${b}") [["" "a"] ["" "d" "f"]];
                flagAttrs = lib.genAttrs flagAliasCombos convertFlagAliasesToFlags;
                aliasTemplate = name: value: {
                    "l${name}" = "${list} --oneline --dereference ${value}";
                    "ll${name}" = "${list} --long ${value}";
                    "lt${name}" = "${list} --tree ${value}";
                };
                flaggedAliases = lib.concatMapAttrs aliasTemplate flagAttrs;
            in
                flaggedAliases // {ls = "l";};

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
