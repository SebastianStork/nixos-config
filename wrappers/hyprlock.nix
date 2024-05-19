{ assembleWrapper, pkgs, ... }:
assembleWrapper {
  basePackage = pkgs.hyprlock;

  flags =
    let
      hyprlock-config = pkgs.writeText "hyprlock-config" ''
        background {
          monitor =
          path = screenshot
          blur_size = 4
          blur_passes = 1
        }
        input-field {
          monitor =
        }
      '';
    in
    [
      "--config"
      hyprlock-config
    ];
}
