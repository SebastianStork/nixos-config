{ ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/92437114-de06-4a78-9ee3-c7d0ffcabf95";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D8B4-1218";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/1eba93d1-4853-4534-8cfd-5c14e29c6ff6"; } ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [ "kvm-amd" ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
  ];

  zramSwap.enable = true;
  services.fstrim.enable = true;
}
