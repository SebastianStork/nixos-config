{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.vm.qemu.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.vm.qemu.enable {
    virtualisation.libvirtd.enable = true;

    programs.virt-manager.enable = true;

    environment.systemPackages = [ pkgs.quickemu ];

    home-manager.sharedModules = [
      {
        dconf.settings."org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      }
    ];
  };
}
