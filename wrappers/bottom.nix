{ inputs, pkgs, ... }:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.bottom = {
        basePackage = pkgs.bottom;
        flags = [ "--group_processes" ];
      };
    }
  ];
}).config.wrappers.bottom.wrapped
