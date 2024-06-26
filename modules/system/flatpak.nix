{ config, lib, ... }:
{
  options.myConfig.flatpak.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.flatpak.enable { services.flatpak.enable = true; };
}
