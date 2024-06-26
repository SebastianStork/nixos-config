{ config, lib, ... }:
{
  options.myConfig.virtualisation.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.virtualisation.enable {
    dconf.settings."org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
