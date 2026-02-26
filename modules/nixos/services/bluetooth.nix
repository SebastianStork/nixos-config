{ config, lib, ... }:
{
  options.custom.services.bluetooth.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.bluetooth.enable {
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
