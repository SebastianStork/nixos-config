{ config, inputs, ... }:
{
  imports = [ inputs.nixos-hardware.nixosModules.hardkernel-odroid-h4 ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    kernelModules = [
      "kvm-intel"
      "coretemp"
      "it87"
    ];
    extraModulePackages = [ config.boot.kernelPackages.it87 ];
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

  # Ensure pwm2_enable is set to 2 (automatic) before fancontrol starts,
  # because the IT8613E can't transition 0 -> 1 (manual) directly,
  # but can do 2 -> 1 which fancontrol requires.
  systemd.services.fancontrol-pwm-init = {
    description = "Initialize IT8613E PWM mode for fancontrol";
    before = [ "fancontrol.service" ];
    requiredBy = [ "fancontrol.service" ];
    serviceConfig.Type = "oneshot";
    script = "echo 2 > /sys/devices/platform/it87.2608/hwmon/hwmon*/pwm2_enable";
    unitConfig.ConditionPathExists = "/sys/devices/platform/it87.2608";
  };

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
}
