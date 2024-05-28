{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.myConfig.shell.enable {
    home.packages = [
      pkgs.eza
      pkgs.bat
    ];

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
      in
      lib.mkMerge [
        nixAliases
        lsAliases
        catAlias
      ];
  };
}
