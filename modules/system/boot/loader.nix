{ config, lib, ... }:
{
  options.myConfig.boot.loader.systemd-boot.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.boot.loader.systemd-boot.enable {
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
  };
}
