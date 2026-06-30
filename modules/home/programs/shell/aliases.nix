{
  config,
  self,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.shell.aliases.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.shell.aliases.enable {
    programs.zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };

    home = {
      packages = [
        pkgs.eza
        pkgs.bat
      ];

      shellAliases =
        let
          lsAliases =
            let
              eza = [
                "eza"
                "--header"
                "--group"
                "--time-style=long-iso"
                "--group-directories-first"
                "--sort=name"
                "--icons=auto"
                "--git"
                "--git-repos-no-status"
                "--binary"
              ];

              aliasPartsToCommand =
                aliasParts:
                let
                  flags =
                    aliasParts
                    |> lib.filter (aliasPart: aliasPart != "")
                    |> lib.map (
                      aliasPart:
                      {
                        "l" = "--oneline --dereference";
                        "ll" = "--long";
                        "lt" = "--tree";
                        "a" = "--all";
                        "d" = "--only-dirs";
                        "f" = "--only-files";
                      }
                      .${aliasPart}
                    );
                in
                eza ++ flags |> self.lib.concatWords;
            in
            {
              format = [
                "l"
                "ll"
                "lt"
              ];
              visibility = [
                ""
                "a"
              ];
              restriction = [
                ""
                "d"
                "f"
              ];
            }
            |> lib.mapCartesianProduct (
              {
                format,
                visibility,
                restriction,
              }:
              [
                format
                visibility
                restriction
              ]
            )
            |> self.lib.genAttrs' (
              aliasParts: lib.nameValuePair (lib.concatStrings aliasParts) (aliasPartsToCommand aliasParts)
            );
        in
        lsAliases
        // {
          ls = "l";
          cat =
            let
              theme =
                {
                  dark = "";
                  light = "GitHub";
                }
                .${config.custom.theme};
            in
            "bat --plain --theme=${theme} --paging=never";
        };
    };
  };
}
