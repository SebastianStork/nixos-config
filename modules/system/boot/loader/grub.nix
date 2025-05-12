{ config, lib, ... }:
{
  options.myConfig.boot.loader.grub.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.boot.loader.grub.enable {
    boot = {
      tmp.cleanOnBoot = true;
      loader.grub.enable = true;
    };
  };
}
