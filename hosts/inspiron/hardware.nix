{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.default ];

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
    logind.lidSwitch = "ignore";
  };

  # Allow access to labrador usb device
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", MODE="0666"
    SUBSYSTEM=="usb_device", ATTRS{idVendor}=="03eb", MODE="0666"
  '';
}
