{ inputs, pkgs, ... }:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.bottom = {
        basePackage = pkgs.bottom;
        flags = [ "--group" ];
      };
    }
  ];
}).config.wrappers.bottom.wrapped
