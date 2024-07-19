{ config, lib, ... }:
{
  options.myConfig.boot.silent = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.boot.silent {
    boot = {
      kernelParams = [
        "quiet"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
      consoleLogLevel = 3;
      initrd.verbose = false;
      initrd.systemd.enable = true;
      plymouth.enable = true;
    };
  };
}
