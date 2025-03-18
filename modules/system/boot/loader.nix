{ config, lib, ... }:
{
  options.myConfig.boot.loader.systemdBoot.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.boot.loader.systemdBoot.enable {
    boot = {
      tmp.cleanOnBoot = true;
      loader = {
        systemd-boot = {
          enable = true;
          editor = false;
          configurationLimit = 20;
        };
        efi.canTouchEfiVariables = true;
        timeout = 0;
      };
    };
    systemd.watchdog.rebootTime = "10";
  };
}
