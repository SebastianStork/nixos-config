{ inputs, pkgs, ... }:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.spotify = {
        basePackage = pkgs.spotify;
        flags = [ "--disable-gpu" ];
      };
    }
  ];
}).config.wrappers.spotify.wrapped
