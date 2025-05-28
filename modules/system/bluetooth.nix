{ config, lib, ... }:
{
  options.custom.bluetooth.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.bluetooth.enable {
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
