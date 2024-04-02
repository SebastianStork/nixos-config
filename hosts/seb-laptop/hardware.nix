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

    services.autorandr = {
        enable = true;
        profiles = {
            "laptop" = {
                fingerprint = {
                    "eDP-1" = "00ffffffffffff000dae221500000000161e0104a52213780328659759548e271e5054000000010101010101010101010101010101015c6f80a070383e403020a50058c11000001a000000fd00307889891d010a202020202020000000fe00594d485748803135364852410a000000000001410f99001000000b010a2020016970137900000301145c6f00047f079f002f001f003704b4040900040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a90";
                };
                config = {
                    "eDP-1" = {
                        enable = true;
                        primary = true;
                        position = "0x0";
                        mode = "1920x1080";
                        rate = "60";
                    };
                };
            };
        };
    };
    services.xserver.displayManager.sessionCommands = "autorandr -c";

    services.auto-cpufreq.enable = true;
}
