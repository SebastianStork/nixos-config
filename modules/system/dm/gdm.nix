{ config, lib, ... }:
{
  options.myConfig.dm.gdm.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.dm.gdm.enable {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
    };
  };
}
