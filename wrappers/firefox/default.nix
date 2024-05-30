{ assembleWrapper, moduleArgs, ... }:
let
  inherit (moduleArgs) pkgs;
in
assembleWrapper {
  basePackage = pkgs.wrapFirefox pkgs.firefox-unwrapped {
    extraPolicies.ExtensionSettings = import ./extensions.nix { inherit moduleArgs; };
    extraPrefs = import ./preferences.nix { inherit moduleArgs; };
  };
}
