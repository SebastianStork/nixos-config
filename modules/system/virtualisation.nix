{ config, lib, ... }:
{
  options.myConfig.virtualisation.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.virtualisation.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    virtualisation.virtualbox.host.enable = true;
  };
}
