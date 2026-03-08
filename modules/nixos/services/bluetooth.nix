{ config, lib, ... }:
{
  options.custom.services.bluetooth.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.bluetooth.enable {
    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = false;
      };
      logitech.wireless.enable = true;
    };

    services.blueman.enable = true;
  };
}
