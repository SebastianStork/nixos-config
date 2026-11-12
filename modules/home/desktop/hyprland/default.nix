{
  config,
  osConfig,
  lib,
  ...
}:
{
  options.custom.desktop.hyprland.enable = lib.mkEnableOption "" // {
    default = osConfig.custom.desktop.hyprland.enable;
  };

  config = lib.mkIf config.custom.desktop.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      package = null;
      portalPackage = null;
    };

    custom = {
      programs = {
        foot.enable = true;
        noctalia.enable = true;
      };
      services.cliphist.enable = true;
    };
  };
}
