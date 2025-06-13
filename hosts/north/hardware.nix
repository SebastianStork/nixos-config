{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.default ];

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };

  boot = {
    kernelModules = [
      "kvm-amd"
      "k10temp"
      "nct6775"
    ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
  };

  # Disable until https://github.com/NixOS/nixpkgs/issues/368642 is resolved
  # hardware.logitech.lcd.enable = true;

  services = {
    fstrim.enable = true;

    # Prevent immediate wake-up from suspend caused by the logi bolt receiver
    udev.extraRules = ''
      ACTION=="add" SUBSYSTEM=="pci" ATTR{vendor}=="0x1022" ATTR{device}=="0x43ee" ATTR{power/wakeup}="disabled"
    '';
  };

  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."10-enp6s0" = {
      matchConfig.Name = "enp6s0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  hardware.fancontrol = {
    enable = true;
    config = ''
      # pwm1=rear pwm2=cpu pwm3=front+top
      INTERVAL=2
      DEVPATH=hwmon1=devices/pci0000:00/0000:00:18.3 hwmon2=devices/platform/nct6775.656
      DEVNAME=hwmon1=k10temp hwmon2=nct6798
      FCTEMPS=hwmon2/pwm1=hwmon2/temp1_input hwmon2/pwm2=hwmon1/temp1_input hwmon2/pwm3=hwmon2/temp1_input
      FCFANS=hwmon2/pwm1=hwmon2/fan1_input hwmon2/pwm2=hwmon2/fan7_input+hwmon2/fan2_input hwmon2/pwm3=hwmon2/fan3_input
      MINTEMP=hwmon2/pwm1=35 hwmon2/pwm2=45 hwmon2/pwm3=35
      MAXTEMP=hwmon2/pwm1=100 hwmon2/pwm2=100 hwmon2/pwm3=100
      MINSTART=hwmon2/pwm1=16 hwmon2/pwm2=16 hwmon2/pwm3=16
      MINSTOP=hwmon2/pwm1=16 hwmon2/pwm2=16 hwmon2/pwm3=16
    '';
  };
}
