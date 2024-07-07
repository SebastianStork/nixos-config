{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs lib;
in
{
  theme ? "dark",
}:
assembleWrapper {
  basePackage = pkgs.rofi-wayland;
  flags =
    let
      theming =
        {
          dark = ''
            * {
              background:     #1E2127FF;
              background-alt: #282B31FF;
              foreground:     #FFFFFFFF;
              selected:       #61AFEFFF;
              active:         #98C379FF;
              urgent:         #E06C75FF;
            }
          '';
          light = ''
            * {
              background:     #F1F1F1FF;
              background-alt: #E0E0E0FF;
              foreground:     #252525FF;
              selected:       #008EC4FF;
              active:         #10A778FF;
              urgent:         #C30771FF;
            }
          '';
        }
        .${theme};
      rofi-config = pkgs.writeText "rofi-config" (
        lib.concatLines [
          theming
          (builtins.readFile ./config.rasi)
        ]
      );
    in
    [
      "-config"
      rofi-config
    ];
}
