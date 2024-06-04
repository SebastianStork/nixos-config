{ config, lib, ... }:
{
  options.myConfig.boot = {
    loader.systemd-boot.enable = lib.mkEnableOption "";
    silent = lib.mkEnableOption "";
  };

  config = lib.mkMerge [
    (lib.mkIf config.myConfig.boot.loader.systemd-boot.enable {
      boot.tmp.cleanOnBoot = true;
      boot.loader = {
        systemd-boot = {
          enable = true;
          editor = false;
          configurationLimit = 20;
        };
        efi.canTouchEfiVariables = true;
        timeout = 0;
      };
      systemd.watchdog.rebootTime = "10";
    })

    (lib.mkIf config.myConfig.boot.silent {
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
      };
    })
  ];
}
