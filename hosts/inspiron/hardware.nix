{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.default
    ./disko.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [ "kvm-amd" ];
boot.initrd.kernelModules = [ "usb_storage" ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
        "sd_mod"
  ];

  zramSwap.enable = true;
  services.fstrim.enable = true;
  services.fwupd.enable = true;
}
