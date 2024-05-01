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
                flagCombos = lib.crossLists (a: b: "${a}${b}") [["" "a"] ["" "d" "f"]];
                getFlags = str:
                    lib.concatStringsSep " " (lib.forEach (lib.stringToCharacters str) (x:
                        {
                            a = "--all";
                            d = "--only-dirs";
                            f = "--only-files";
                        }
                        .${x}));
                flaggedAliases = lib.concatMapAttrs (name: value: {
                    "l${name}" = "l ${value}";
                    "ll${name}" = "ll ${value}";
                    "lt${name}" = "lt ${value}";
                }) (lib.genAttrs flagCombos (str: "${getFlags str}"));
            in
                flaggedAliases
                // {
                    ls = "l";
                    l = "${list} --oneline --dereference";
                    ll = "${list} --long";
                    lt = "${list} --tree";
                };

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
