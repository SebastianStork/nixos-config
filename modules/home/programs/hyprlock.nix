{
  config,
  osConfig,
  modulesPath,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.programs.hyprlock;
in
{
  imports = [ "${modulesPath}/programs/hyprlock.nix" ];

  options.custom.programs.hyprlock = {
    enable = lib.mkEnableOption "";
    fprintAuth = lib.mkEnableOption "" // {
      default = osConfig.services.fprintd.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      package = pkgs-unstable.hyprlock;

      settings = {
        general.hide_cursor = true;
        auth."fingerprint:enabled" = cfg.fprintAuth;
        animations.enabled = false;
        input-field.monitor = "";

        background =
          [
            "DP-1"
            "eDP-1"
          ]
          |> lib.map (monitor: {
            inherit monitor;
            path = "~/.local/state/wpaperd/wallpapers/${monitor}";
          });
      };
    };
  };
}
