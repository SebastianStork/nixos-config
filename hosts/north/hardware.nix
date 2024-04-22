{
    inputs,
    config,
    pkgs,
    lib,
    ...
}: {
    imports = [
        inputs.disko.nixosModules.default
        ./disko.nix
    ];

    hardware.enableRedistributableFirmware = true;
    boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
    ];
    boot.kernelModules = [
        "kvm-amd"
        "adm1021"
        "nct6775"
    ];
    nixpkgs.hostPlatform = "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = true;

    services.xserver.videoDrivers = ["nvidia"];
    hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        package = let
            rcu_patch = pkgs.fetchpatch {
                url = "https://github.com/gentoo/gentoo/raw/c64caf53/x11-drivers/nvidia-drivers/files/nvidia-drivers-470.223.02-gpl-pfn_valid.patch";
                hash = "sha256-eZiQQp2S/asE7MfGvfe6dA/kdCvek9SYa/FFGp24dVg=";
            };
            linux_6_8_patch = pkgs.fetchpatch {
                url = "https://gist.github.com/joanbm/24f4d4f4ec69f0c37038a6cc9d132b43/raw/bacb9bf3617529d54cb9a57ae8dc9f29b41d4362/nvidia-470xx-fix-linux-6.8.patch";
                hash = "sha256-SPLC2uGdjHSy4h9i3YFjQ6se6OCdWYW6tlC0CtqmP50=";
                extraPrefix = "kernel/";
                stripLen = 1;
            };
        in
            config.boot.kernelPackages.nvidiaPackages.mkDriver {
                version = "535.129.03";
                sha256_64bit = "sha256-5tylYmomCMa7KgRs/LfBrzOLnpYafdkKwJu4oSb/AC4=";
                sha256_aarch64 = "sha256-i6jZYUV6JBvN+Rt21v4vNstHPIu9sC+2ZQpiLOLoWzM=";
                openSha256 = "sha256-/Hxod/LQ4CGZN1B1GRpgE/xgoYlkPpMh+n8L7tmxwjs=";
                settingsSha256 = "sha256-QKN/gLGlT+/hAdYKlkIjZTgvubzQTt4/ki5Y+2Zj3pk=";
                persistencedSha256 = "sha256-FRMqY5uAJzq3o+YdM2Mdjj8Df6/cuUUAnh52Ne4koME=";

                patches = [
                    rcu_patch
                    linux_6_8_patch
                ];
            };
    };

    systemd.services.gpu-temp-reader = {
        wantedBy = ["multi-user.target"];
        requires = ["fancontrol.service"];
        before = ["fancontrol.service"];

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
            AVERAGE=5
            DEVPATH=hwmon0=devices/platform/nct6775.656 hwmon1=devices/pci0000:00/0000:00:18.3
            DEVNAME=hwmon0=nct6798 hwmon1=k10temp
            FCTEMPS=hwmon0/pwm1=hwmon0/temp1_input hwmon0/pwm2=hwmon1/temp1_input hwmon0/pwm3=hwmon0/temp1_input hwmon0/pwm4=/tmp/nvidia-gpu-temp hwmon0/pwm5=hwmon0/temp1_input
            FCFANS=hwmon0/pwm1=hwmon0/fan1_input hwmon0/pwm2=hwmon0/fan7_input+hwmon0/fan2_input hwmon0/pwm3=hwmon0/fan3_input hwmon0/pwm4=hwmon0/fan4_input hwmon0/pwm5=hwmon0/fan5_input
            MINTEMP=hwmon0/pwm1=35 hwmon0/pwm2=45 hwmon0/pwm3=35 hwmon0/pwm4=40 hwmon0/pwm5=35
            MAXTEMP=hwmon0/pwm1=100 hwmon0/pwm2=100 hwmon0/pwm3=100 hwmon0/pwm4=100 hwmon0/pwm5=100
            MINSTART=hwmon0/pwm1=16 hwmon0/pwm2=16 hwmon0/pwm3=16 hwmon0/pwm4=30 hwmon0/pwm5=16
            MINSTOP=hwmon0/pwm1=16 hwmon0/pwm2=16 hwmon0/pwm3=16 hwmon0/pwm4=30 hwmon0/pwm5=16
        '';
    };
}