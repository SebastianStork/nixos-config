{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.myConfig.shell.zsh.enable {
    home.packages = [
      pkgs.eza
      pkgs.bat
      pkgs.bottom
    ];

    home.shellAliases =
      let
        lsAliases =
          let
            aliasList =
              lib.mapCartesianProduct
                (
                  {
                    a,
                    b,
                    c,
                  }:
                  a + b + c
                )
                {
                  a = [
                    "ll"
                    "lt"
                    "l"
                  ];
                  b = [
                    ""
                    "a"
                  ];
                  c = [
                    ""
                    "d"
                    "f"
                  ];
                };
            convertAliasToCmd =
              str:
              "eza --header --group --time-style=long-iso --group-directories-first --sort=name --icons=auto --git --git-repos-no-status --binary "
              + (builtins.replaceStrings
                [
                  "ll"
                  "lt"
                  "l"
                  "a"
                  "d"
                  "f"
                ]
                [
                  "--long "
                  "--tree "
                  "--oneline --dereference "
                  "--all "
                  "--only-dirs "
                  "--only-files "
                ]
                str
              );
          in
          (lib.genAttrs aliasList convertAliasToCmd) // { ls = "l"; };

        catAlias =
          let
            theme =
              {
                dark = "";
                light = "GitHub";
              }
              .${config.myConfig.theme};
          in
          {
            cat = "bat --plain --theme=${theme}";
          };

        bottomAlias = {
          btm = "btm --group";
        };
      in
      lib.mkMerge [
        lsAliases
        catAlias
        bottomAlias
      ];
  };
}
