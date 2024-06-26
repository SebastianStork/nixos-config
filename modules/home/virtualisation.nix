{ config, lib, ... }@moduleArgs:
{
  options.myConfig.virtualisation.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.myConfig.virtualisation.enable or false;
  };

  config = lib.mkIf config.myConfig.virtualisation.enable {
    dconf.settings."org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
