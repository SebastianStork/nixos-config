{pkgs, ...}: {
    imports = [
        ../default.nix
        ./hardware.nix
    ];

    networking.hostName = "dell-laptop";

    myConfig = {
        boot-loader.systemd-boot.enable = true;

        dm.lightdm.enable = true;
        de.qtile.enable = true;

        wlan.enable = true;
        bluetooth.enable = true;

        sound.pipewire.enable = true;
        auto-gc.enable = true;
        vm.qemu.enable = true;
        flatpak.enable = true;
        vpn.lgs.enable = true;
        comma.enable = true;
        sops.enable = true;
        auto-cpufreq.enable = true;
        doas.enable = false;
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;
    services.gvfs.enable = true;

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
}
