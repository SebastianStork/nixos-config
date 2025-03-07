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
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "usb_storage"
      "sd_mod"
    ];
  };

  services = {
    fwupd.enable = true;
    logind.lidSwitch = "ignore";
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
    };
  };
}
