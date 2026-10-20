{ config, lib, ... }:
let
  cfg = config.custom.services.bluetooth;
in
{
  options.custom.services.bluetooth = {
    enable = lib.mkEnableOption "";
    powerOnBoot = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      inherit (cfg) powerOnBoot;
    };
  };
}
