{ inputs, pkgs, ... }:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.obsidian = {
        basePackage = pkgs.obsidian;
        flags = [ "--disable-gpu" ];
      };
    }
  ];
}).config.wrappers.obsidian.wrapped
