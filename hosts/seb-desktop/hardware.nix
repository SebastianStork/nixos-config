{inputs, ...}: {
    imports = [
        inputs.disko.nixosModules.default
        ./disko.nix
    ];

    hardware.enableRedistributableFirmware = true;
    boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
    boot.kernelModules = ["kvm-amd" "adm1021" "nct6775"];
    nixpkgs.hostPlatform = "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = true;

    services.xserver.videoDrivers = ["nvidia"];
    hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
    };

    services.autorandr = {
        enable = true;
        profiles = {
            "primary" = {
                fingerprint = {
                    "DP-2" = "00ffffffffffff0005e30227262602001a1e0104a53c22783bdad5ad5048a625125054bfef00d1c081803168317c4568457c6168617c565e00a0a0a029503020350055502100001e40e7006aa0a067500820980455502100001a000000fc0051323747325747340a20202020000000fd003090e6e63c010a20202020202001e702031ff14c0103051404131f120211903f230907078301000065030c0010006fc200a0a0a055503020350055502100001e5aa000a0a0a046503020350055502100001e023a801871382d40582c450055502100001eab22a0a050841a303020360055502100001af03c00d051a0355060883a0055502100001c00000000000080";
                };
                config = {
                    "DP-2" = {
                        enable = true;
                        primary = true;
                        position = "0x0";
                        mode = "2560x1440";
                        rate = "144";
                    };
                };
            };
        };
    };
    services.xserver.displayManager.sessionCommands = "autorandr -c";

    systemd.services.gpu-temp-reader = {
        wantedBy = ["multi-user.target"];
        requires = ["fancontrol.service"];
        before = ["fancontrol.service"];

        script = ''
            /run/current-system/sw/bin/touch /tmp/nvidia-gpu-temp
            while :; do
                temp="$(/run/current-system/sw/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)"
                /run/current-system/sw/bin/echo "$((temp * 1000))" > /tmp/nvidia-gpu-temp
                /run/current-system/sw/bin/sleep 2
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
