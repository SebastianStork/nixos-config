{ config, lib, ... }:
{
  imports = [
    ./config.nix
    ./keybinds.nix
  ];

  options.myConfig.de.hyprland.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.hyprland.enable {
    myConfig.de = {
      hypridlelock.enable = true;
      waybar.enable = true;
    };
  };
}
