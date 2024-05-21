{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.myConfig.shell.enable {
    home.shellAliases =
      let
        nixAliases =
          let
            rebuild = "sudo -v && nh os";
          in
          {
            nrs = "${rebuild} switch";
            nrt = "${rebuild} test";
            nrb = "${rebuild} boot";
            nrrb = "nrb && reboot";
          };

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
              "${lib.getExe pkgs.eza} --header --group --time-style=long-iso --group-directories-first --sort=name --icons=auto --git --git-repos-no-status --binary "
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
              .${config.myConfig.de.theme};
          in
          {
            cat = "${lib.getExe pkgs.bat} --plain --theme=${theme}";
          };
      in
      lib.mkMerge [
        nixAliases
        lsAliases
        catAlias
      ];
  };
}
