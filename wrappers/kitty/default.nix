{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
{
  theme ? "dark",
}:
assembleWrapper {
  basePackage = pkgs.kitty;

  programs.kitty.prependFlags =
    let
      theme-file =
        {
          dark = "default.conf";
          light = "GitHub_Light.conf";
        }
        .${theme};
      kitty-theme = "include=${pkgs.kitty-themes}/share/kitty-themes/themes/${theme-file}";
    in
    [
      "--config"
      ./kitty.conf
      "--override"
      kitty-theme
    ];
}
