{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.custom.programs.shell.zsh.enable {
    home.packages = [
      pkgs.eza
      pkgs.bat
    ];

    home.shellAliases = 
      let
        lsAliases = 
          let
            aliasList = lib.mapCartesianProduct ({ a, b, c }: a + b + c) { a = ["ll" "lt" "l"]; b = ["" "a"]; c = ["" "d" "f"]; };
            eza = "eza --header --group --time-style=long-iso --group-directories-first --sort=name --icons=auto --git --git-repos-no-status --binary ";
            convertAliasToCmd = str: eza + (builtins.replaceStrings ["ll" "lt" "l" "a" "d" "f"] ["--long " "--tree " "--oneline --dereference " "--all " "--only-dirs " "--only-files "] str);
          in
          (lib.genAttrs aliasList convertAliasToCmd) // { ls = "l"; };

        catAlias =
          let
            theme = 
              {
                dark = "";
                light = "GitHub";
              }
              .${config.custom.theme};
          in
          {
            cat = "bat --plain --theme=${theme}";
          };

          bottomAlias.btm = "btm --group_processes";
      in
      lib.mkMerge [
        lsAliases
        catAlias
        bottomAlias
      ];
  };
}
