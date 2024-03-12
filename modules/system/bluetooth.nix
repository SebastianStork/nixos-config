{
  config,
  lib,
  ...
}: {
  options.myConfig.bluetooth.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = true;
    hardware.logitech.wireless.enable = true;
  };
}
