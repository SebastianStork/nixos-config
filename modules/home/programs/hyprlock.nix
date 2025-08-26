{
  config,
  pkgs-unstable,
  lib,
  ...
}@moduleArgs:
let
  cfg = config.custom.programs.hyprlock;
in
{
  options.custom.programs.hyprlock = {
    enable = lib.mkEnableOption "";
    fprintAuth = lib.mkEnableOption "" // {
      default = moduleArgs.osConfig.services.fprintd.enable or false;
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
