{pkgs, ...}: {
    imports = [
        ../common.nix
        ./hardware.nix
    ];

    networking.hostName = "seb-desktop";

    environment.sessionVariables.FLAKE = "/home/seb/Projects/nixos/my-config";

    myConfig = {
        boot-loader = {
            systemd-boot.enable = true;
            silent = true;
        };

        dm.tuigreet.enable = true;
        de.hyprland.enable = true;

        sound.enable = true;
        auto-gc.enable = true;
        vm.qemu.enable = true;
        vpn.lgs.enable = true;
        comma.enable = true;
        sops.enable = true;
        printing.enable = true;
        syncthing.enable = true;
        nix-helper.enable = true;
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;
    services.gvfs.enable = true;

    programs.steam.enable = true;
}
