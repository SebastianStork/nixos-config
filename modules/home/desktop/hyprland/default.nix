{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.desktop.hyprland.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.desktop.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      package = null;
      portalPackage = null;
    };

    custom = {
      programs.noctalia.enable = true;

      services = {
        cliphist.enable = true;
        hypridle = {
          enable = true;
          lockCommand = "noctalia msg session lock";
        };
      };
    };

    home.packages = [
      pkgs.grim
      pkgs.jq
      pkgs.satty
      pkgs.slurp
    ];
  };
}
