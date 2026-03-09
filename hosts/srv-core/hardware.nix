{ inputs, ... }:
{
  imports = [ inputs.nixos-hardware.nixosModules.hardkernel-odroid-h4 ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    kernelModules = [
      "kvm-intel"
      "coretemp"
      "it87"
    ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "sd_mod"
      "sdhci_pci"
    ];
    kernelParams = [
      "zswap.enabled=1"
      "zswap.shrinker_enabled=1"
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
