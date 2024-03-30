{pkgs, ...}: {
    imports = [
        ../default.nix
        ./hardware.nix
    ];

    networking.hostName = "seb-desktop";

    environment.sessionVariables.FLAKE = "/home/seb/Projects/nixos/my-config";

    myConfig = {
        boot-loader.systemd-boot.enable = true;

        dm.sddm.enable = true;
        de.qtile.enable = true;

        sound.pipewire.enable = true;
        auto-gc.enable = true;
        vm.qemu.enable = true;
        flatpak.enable = true;
        vpn.lgs.enable = true;
        comma.enable = true;
        sops.enable = true;
        printing.enable = true;
        syncthing.enable = true;
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;
    services.gvfs.enable = true;

    programs.steam.enable = true;
}
