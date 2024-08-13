{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.default
    ./disko.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };

  boot = {
    kernelModules = [ "kvm-amd" ];
    initrd.kernelModules = [ "usb_storage" ];
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "sd_mod"
    ];
  };

  services = {
    fstrim.enable = true;
    fwupd.enable = true;
    auto-cpufreq.enable = true;
  };
}
