{ inputs, pkgs, ... }:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.waybar = {
        basePackage = pkgs.waybar;
        flags = [
          "--config"
          ./config.json
          "--style"
          ./style.css
        ];
      };
    }
  ];
}).config.wrappers.waybar.wrapped
