{ config, lib, ... }@moduleArgs:
{
  options.myConfig.virt-manager.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.programs.virt-manager.enable or false;
  };

  config = lib.mkIf config.myConfig.virt-manager.enable {
    dconf.settings."org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
