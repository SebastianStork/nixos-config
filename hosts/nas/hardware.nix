_: {
  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    kernelModules = [ "kvm-intel" ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "sd_mod"
      "sdhci_pci"
    ];

    supportedFilesystems = [ "bcachefs" ];

    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        efiSupport = true;
        mirroredBoots = [
          {
            devices = [ "nodev" ];
            path = "/boot1";
          }
          {
            devices = [ "nodev" ];
            path = "/boot2";
          }
        ];
      };
    };
  };
}
