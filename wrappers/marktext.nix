{ inputs, pkgs, ... }:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.marktext = {
        basePackage = pkgs.marktext;
        flags = [ "--disable-gpu" ];
      };
    }
  ];
}).config.wrappers.marktext.wrapped
