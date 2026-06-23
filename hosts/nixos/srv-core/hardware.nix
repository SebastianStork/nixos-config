{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.nixos-hardware.nixosModules.hardkernel-odroid-h4 ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    kernelModules = [
      "kvm-intel"
      "coretemp"
      "it87"
    ];
    extraModulePackages = [
      # Compress + hiPrio so the fork overrides the in-tree it87.ko.xz (which lacks IT8613 support).
      (lib.hiPrio (
        config.boot.kernelPackages.it87.overrideAttrs {
          postInstall = ''xz "$out/lib/modules/"*/kernel/drivers/hwmon/it87.ko'';
        }
      ))
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

  fileSystems."/persist".depends = [ "/nix" ];

  hardware.fancontrol = {
    enable = true;
    config = ''
      INTERVAL=5
      DEVPATH=hwmon1=devices/platform/coretemp.0 hwmon2=devices/platform/it87.2608
      DEVNAME=hwmon1=coretemp hwmon2=it8613
      FCTEMPS=hwmon2/pwm2=hwmon1/temp1_input
      FCFANS=hwmon2/pwm2=hwmon2/fan2_input
      MINTEMP=hwmon2/pwm2=70
      MAXTEMP=hwmon2/pwm2=100
      MINSTART=hwmon2/pwm2=35
      MINSTOP=hwmon2/pwm2=25
    '';
  };
  systemd.services.fancontrol.preStart = "echo 2 > /sys/devices/platform/it87.2608/hwmon/hwmon*/pwm2_enable";
}
