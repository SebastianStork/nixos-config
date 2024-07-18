{ inputs, pkgs, ... }:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.hyprlock = {
        basePackage = pkgs.hyprlock;
        flags =
          let
            hyprlock-config = pkgs.writeText "hyprlock-config" ''
              general {
                no_fade_in = true
              }
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
      };
    }
  ];
}).config.wrappers.hyprlock.wrapped
