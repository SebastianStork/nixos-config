{pkgs, ...}: {
    imports = [
        ../common.nix
        ./hardware.nix
    ];

    networking.hostName = "north";

    environment.sessionVariables.FLAKE = "/home/seb/Projects/nixos/my-config";

    myConfig = {
        boot-loader = {
            systemd-boot.enable = true;
            silent = true;
        };

        dm.gdm.enable = true;
        de.hyprland.enable = true;

        sound.enable = true;
        auto-gc.enable = true;
        vm.qemu.enable = true;
        vpn.lgs.enable = true;
        comma.enable = true;
        sops.enable = true;
        printing.enable = true;
        syncthing.enable = true;
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;

    programs.nh.enable = true;
    programs.steam.enable = true;
}
