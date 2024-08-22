{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.default
    ./disko.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
  };

  boot = {
    kernelModules = [ "kvm-intel" ];
    initrd.kernelModules = [ "usb_storage" ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usb_storage"
      "sd_mod"
    ];
  };

  zramSwap.enable = true;
  services = {
    thermald.enable = true;
    fstrim.enable = true;
  };
}
