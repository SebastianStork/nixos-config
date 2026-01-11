{ modulesPath, lib, ... }:
{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];

  zramSwap.enable = true;

  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-enp1s0" = {
      matchConfig.Name = "enp1s0";
      linkConfig.RequiredForOnline = "routable";
      address = [ "167.235.73.246/32" ];
      routes = lib.singleton {
        Gateway = "172.31.1.1";
        GatewayOnLink = true;
      };
      dns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };
}
