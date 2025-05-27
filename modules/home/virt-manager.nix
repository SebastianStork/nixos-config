{ config, lib, ... }@moduleArgs:
{
  options.custom.programs.virt-manager.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.programs.virt-manager.enable or false;
  };

  config = lib.mkIf config.custom.programs.virt-manager.enable {
    dconf.settings."org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
