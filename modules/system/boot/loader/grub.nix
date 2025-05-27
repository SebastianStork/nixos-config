{ config, lib, ... }:
{
  options.custom.boot.loader.grub.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.boot.loader.grub.enable {
    boot = {
      tmp.cleanOnBoot = true;
      loader.grub.enable = true;
    };
  };
}
