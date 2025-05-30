{ config, lib, ... }:
{
  options.custom.boot.loader.systemdBoot.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.boot.loader.systemdBoot.enable {
    boot = {
      tmp.cleanOnBoot = true;
      loader = {
        systemd-boot = {
          enable = true;
          editor = false;
          configurationLimit = 20;
        };
        efi.canTouchEfiVariables = true;
      };
    };
  };
}
