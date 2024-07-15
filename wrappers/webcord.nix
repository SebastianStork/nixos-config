{ inputs, pkgs, ... }:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.webcord = {
        basePackage = pkgs.webcord;
        flags = [ "--disable-gpu" ];
      };
    }
  ];
}).config.wrappers.webcord.wrapped
