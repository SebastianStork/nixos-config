{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
{
  theme ? "dark",
}:
assembleWrapper {
  basePackage = pkgs.kitty;

  flags =
    let
      theme-file =
        {
          dark = "default.conf";
          light = "GitHub_Light.conf";
        }
        .${theme};
      kitty-theme = pkgs.writeText "kitty-theme" "include ${pkgs.kitty-themes}/share/kitty-themes/themes/${theme-file}}";
    in
    [
      "--config"
      ./kitty.conf
      "--config"
      kitty-theme
    ];
}
