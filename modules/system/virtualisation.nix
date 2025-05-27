{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.virtualisation.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.virtualisation.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    environment.systemPackages = [ pkgs.quickemu ];

    virtualisation.virtualbox.host.enable = true;
  };
}
