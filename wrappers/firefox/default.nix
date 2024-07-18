{
  inputs,
  pkgs,
  lib,
  ...
}:
(inputs.wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      wrappers.firefox = {
        basePackage = pkgs.wrapFirefox pkgs.firefox-unwrapped {
          extraPolicies.ExtensionSettings = import ./extensions.nix { inherit inputs pkgs lib; };
          extraPrefs = import ./preferences.nix { inherit inputs; };
        };
      };
    }
  ];
}).config.wrappers.firefox.wrapped
