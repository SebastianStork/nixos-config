{ config, lib, ... }:
{
  options.myConfig.boot.silent = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.boot.silent {
    boot = {
      loader.timeout = 0;
      kernelParams = [
        "quiet"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
      initrd = {
        verbose = false;
        systemd.enable = true;
      };
      consoleLogLevel = 3;
      plymouth.enable = true;
    };
  };
}
