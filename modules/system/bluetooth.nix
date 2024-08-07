{ config, lib, ... }:
{
  options.myConfig.bluetooth.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.bluetooth.enable {
    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      logitech.wireless.enable = true;
    };

    services.blueman.enable = true;
  };
}
