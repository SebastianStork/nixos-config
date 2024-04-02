{pkgs, ...}: {
    imports = [
        ../common.nix
        ./hardware.nix
    ];

    networking.hostName = "seb-laptop";

    environment.sessionVariables.FLAKE = "/home/seb/Projects/nixos/my-config";

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
        doas.enable = false;
        printing.enable = true;
        syncthing.enable = true;
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;
    services.gvfs.enable = true;
    
    hardware.brillo.enable = true;
}
