{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.default
    ./disko.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelModules = [
    "kvm-amd"
    "k10temp"
    "nct6775"
  ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];

  zramSwap.enable = true;
  services.fstrim.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  systemd.services.gpu-temp-reader = {
    wantedBy = [ "multi-user.target" ];
    requires = [ "fancontrol.service" ];
    before = [ "fancontrol.service" ];
    script = ''
      ${lib.getExe' pkgs.coreutils "touch"} /tmp/nvidia-gpu-temp
      while :; do
        temp="$(${lib.getExe' config.hardware.nvidia.package "nvidia-smi"} --query-gpu=temperature.gpu --format=csv,noheader,nounits)"
        ${lib.getExe' pkgs.coreutils "echo"} "$((temp * 1000))" > /tmp/nvidia-gpu-temp
        ${lib.getExe' pkgs.coreutils "sleep"} 2
      done
    '';
  };

  hardware.fancontrol = {
    enable = true;
    config = ''
      # pwm1=rear pwm2=cpu pwm3=front+top pwm4=gpu pwm=motherboard?
      INTERVAL=2
      DEVPATH=hwmon1=devices/pci0000:00/0000:00:18.3 hwmon2=devices/platform/nct6775.656
      DEVNAME=hwmon1=k10temp hwmon2=nct6798
      FCTEMPS=hwmon2/pwm1=hwmon2/temp1_input hwmon2/pwm2=hwmon1/temp1_input hwmon2/pwm3=hwmon2/temp1_input hwmon2/pwm4=/tmp/nvidia-gpu-temp
      FCFANS=hwmon2/pwm1=hwmon2/fan1_input hwmon2/pwm2=hwmon2/fan7_input+hwmon2/fan2_input hwmon2/pwm3=hwmon2/fan3_input hwmon2/pwm4=hwmon2/fan4_input
      MINTEMP=hwmon2/pwm1=35 hwmon2/pwm2=45 hwmon2/pwm3=35 hwmon2/pwm4=40
      MAXTEMP=hwmon2/pwm1=100 hwmon2/pwm2=100 hwmon2/pwm3=100 hwmon2/pwm4=100
      MINSTART=hwmon2/pwm1=16 hwmon2/pwm2=16 hwmon2/pwm3=16 hwmon2/pwm4=30
      MINSTOP=hwmon2/pwm1=16 hwmon2/pwm2=16 hwmon2/pwm3=16 hwmon2/pwm4=30
    '';
  };
}
