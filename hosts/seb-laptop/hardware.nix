{...}: {
    fileSystems."/" = {
        device = "/dev/disk/by-uuid/92437114-de06-4a78-9ee3-c7d0ffcabf95";
        fsType = "ext4";
    };

    fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/D8B4-1218";
        fsType = "vfat";
    };

    swapDevices = [
        {device = "/dev/disk/by-uuid/1eba93d1-4853-4534-8cfd-5c14e29c6ff6";}
    ];

    hardware.enableRedistributableFirmware = true;
    boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod"];
    boot.kernelModules = ["kvm-amd"];
    nixpkgs.hostPlatform = "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = true;
}
